import os
import re
from itertools import combinations
from sentence_transformers import SentenceTransformer, util
import sqlparse
from sqlparse.sql import IdentifierList, Identifier
from sqlparse.tokens import Keyword

# === CONFIGURATION ===
schema_file = "schema.txt"
queries_dir = "original_transactions/functions"
descriptions_dir = "transaction_descriptions"
output_dir = "cot_examples"

plm_model = "sentence-transformers/all-mpnet-base-v2"
MIN_SIMILARITY_THRESHOLD = 0.35

batch_size = 32
device = "cpu"

os.makedirs(output_dir, exist_ok=True)

# === Functions to extract tables and columns from SQL ===

def extract_tables_from_sql(sql_text, schema_dict):
    """
    Extracts REAL table names from SQL, validating against schema.
    This ensures we only get actual database tables, not aliases.
    """
    tables = set()
    
    # Find ALL word identifiers in FROM and JOIN clauses
    # Pattern: FROM/JOIN followed by identifier(s)
    patterns = [
        r'\bfrom\s+([^();]+?)(?:\bwhere\b|\bgroup\b|\border\b|\bhaving\b|\blimit\b|\)|;|$)',
        r'\bjoin\s+([a-z_][a-z0-9_]*)\b'
    ]
    
    for pattern in patterns:
        for match in re.finditer(pattern, sql_text, re.IGNORECASE | re.DOTALL):
            text = match.group(1).strip()
            
            # Skip if contains SELECT (it's a subquery)
            if re.search(r'\bselect\b', text, re.IGNORECASE):
                continue
            
            # Extract all word identifiers
            words = re.findall(r'\b([a-z_][a-z0-9_]*)\b', text, re.IGNORECASE)
            
            for word in words:
                word_lower = word.lower()
                
                # KEY: Only add if it exists in schema_dict
                if word_lower in schema_dict:
                    tables.add(word_lower)
    
    # Also check table.column patterns - the table must be real
    table_column_pattern = r'\b([a-z_][a-z0-9_]*)\.([a-z_][a-z0-9_]*)\b'
    for match in re.finditer(table_column_pattern, sql_text, re.IGNORECASE):
        table = match.group(1).lower()
        if table in schema_dict:
            tables.add(table)
    
    return tables

def extract_columns_from_sql(sql_text, tables, schema_dict):
    """Extracts columns (with and without table prefix)"""
    columns = set()
    
    # 1. Columns with table.column format
    pattern = r'\b(\w+)\.(\w+)\b'
    matches = re.findall(pattern, sql_text)
    
    for table, column in matches:
        table_lower = table.lower()
        if table_lower in tables:
            columns.add(f"{table_lower}.{column.lower()}")
    
    # 2. Columns without prefix (c_custkey, o_orderdate, etc.)
    all_schema_columns = set()
    for table in tables:
        if table in schema_dict:
            for col in schema_dict[table]:
                all_schema_columns.add(col)
    
    sql_lower = sql_text.lower()
    for col in all_schema_columns:
        if re.search(r'\b' + re.escape(col) + r'\b', sql_lower):
            for table in tables:
                if table in schema_dict and col in schema_dict[table]:
                    columns.add(f"{table}.{col}")
                    break
    
    return columns


def extract_values_from_sql(sql_text):
    """
    Extracts literal values from SQL query (parameters and relevant constants).
    Ignores structural SQL values like 0/1 in CASE statements or arithmetic operations.
    """
    values = set()
    
    # 1. Complete dates
    date_pattern = r"date\s+'(\d{4}-\d{2}-\d{2})'"
    for match in re.finditer(date_pattern, sql_text, re.IGNORECASE):
        values.add(match.group(1))
    
    # 2. Timestamps
    timestamp_pattern = r"timestamp\s+'([^']+)'"
    for match in re.finditer(timestamp_pattern, sql_text, re.IGNORECASE):
        values.add(match.group(1))
    
    # 3. Intervals
    interval_pattern = r"interval\s+'([^']+)'"
    for match in re.finditer(interval_pattern, sql_text, re.IGNORECASE):
        values.add(match.group(1))
    
    # 4. Strings in quotes (filter values, parameters)
    string_pattern = r"'([^']*)'"
    for match in re.finditer(string_pattern, sql_text):
        value = match.group(1).strip()
        if value and not re.match(r'\d{4}-\d{2}-\d{2}', value):
            values.add(value)
    
    # 5. Numbers - FILTER structural SQL contexts
    # Remove first: dates, strings, and SQL contexts where numbers are not parameters
    temp_text = sql_text
    
    # Remove dates and timestamps
    temp_text = re.sub(r"(date|timestamp)\s+'[^']+'", '', temp_text, flags=re.IGNORECASE)
    
    # Remove strings
    temp_text = re.sub(r"'[^']+'", '', temp_text)
    
    # Remove common arithmetic operations (1-x, 1+x, x*1, etc.)
    temp_text = re.sub(r'\(\s*1\s*[-+*/]\s*\w+\s*\)', '', temp_text)
    temp_text = re.sub(r'\(\s*\w+\s*[-+*/]\s*1\s*\)', '', temp_text)
    
    # Remove CASE statements with THEN 0/1 and ELSE 0/1
    temp_text = re.sub(r'\bcase\b.*?\bend\b', '', temp_text, flags=re.IGNORECASE | re.DOTALL)
    
    # Remove LIMIT, TOP, OFFSET (they are structural parameters, not filters)
    temp_text = re.sub(r'\b(limit|top|offset)\s+\d+', '', temp_text, flags=re.IGNORECASE)
    
    # Remove numbers in window functions (PARTITION BY, ORDER BY with numbers)
    temp_text = re.sub(r'\border\s+by\s+\d+', '', temp_text, flags=re.IGNORECASE)
    
    # Now capture remaining numbers (these are probably real parameters)
    number_pattern = r'\b(\d+(?:\.\d+)?)\b'
    for match in re.finditer(number_pattern, temp_text):
        num = match.group(1)
        # Ignore isolated 0 and 1 (almost always structural)
        if num not in ['0', '1']:
            values.add(num)
    
    return values


def extract_values_from_description(description):
    """
    Extracts potential parameter values from the description text.
    Focuses on business-relevant values, not UI coordinates or formatting.
    """
    values = set()
    
    # 1. Dates in common formats
    date_patterns = [
        r'\b(\d{4}-\d{2}-\d{2})\b',  # YYYY-MM-DD
        r'\b(\d{2}/\d{2}/\d{4})\b',  # DD/MM/YYYY or MM/DD/YYYY
    ]
    for pattern in date_patterns:
        for match in re.finditer(pattern, description):
            values.add(match.group(1))
    
    # 2. Strings in quotes (likely filter values)
    string_pattern = r"'([^']*)'"
    for match in re.finditer(string_pattern, description):
        value = match.group(1).strip()
        if value:
            values.add(value)
    
    # 3. Numbers - but with heavy filtering to avoid UI coordinates
    temp_text = description
    
    # Remove common UI/formatting patterns
    temp_text = re.sub(r'\d+\s*/\s*\d+', '', temp_text)  # Remove "2/ 12", "4/ 17" patterns
    temp_text = re.sub(r'Row\s*[:/]?\s*Column.*?(?:\n|$)', '', temp_text, flags=re.IGNORECASE)
    temp_text = re.sub(r'Coordinates.*?(?:\n|$)', '', temp_text, flags=re.IGNORECASE)
    temp_text = re.sub(r'\bpage\s+\d+\b', '', temp_text, flags=re.IGNORECASE)
    temp_text = re.sub(r'\bsection\s+\d+', '', temp_text, flags=re.IGNORECASE)
    
    # Look for numbers in business contexts (ranges, thresholds, limits)
    business_patterns = [
        r'within\s+\[(\d+)\s*\.\.\s*(\d+)\]',  # "within [1 .. 10]"
        r'between\s+(\d+)\s+and\s+(\d+)',       # "between 1 and 10"
        r'from\s+(\d+)\s+to\s+(\d+)',           # "from 1 to 10"
        r'up\s+to\s+(\d+)',                      # "up to 10"
        r'at\s+least\s+(\d+)',                   # "at least 90"
        r'(\d+)%',                               # "90%", "80%"
    ]
    
    for pattern in business_patterns:
        for match in re.finditer(pattern, description, re.IGNORECASE):
            for i in range(1, len(match.groups()) + 1):
                if match.group(i):
                    values.add(match.group(i))
    
    return values


def parse_schema(schema_text):
    """
    Parse schema to extract tables and columns from CREATE TABLE statements.
    Adapted for TPC-C format.
    """
    schema_dict = {}
    
    # Pattern to match CREATE TABLE statements
    # Matches: create table table_name ( ... );
    table_pattern = r'create\s+table\s+(\w+)\s*\((.*?)\);'
    
    matches = re.finditer(table_pattern, schema_text, re.IGNORECASE | re.DOTALL)
    
    for match in matches:
        table_name = match.group(1).lower()
        columns_text = match.group(2)
        
        schema_dict[table_name] = []
        
        # Split by comma, but be careful with commas inside constraints
        lines = columns_text.split('\n')
        
        for line in lines:
            line = line.strip()
            
            # Skip empty lines and constraint definitions
            if not line or line.startswith('primary key') or line.startswith('foreign key') or line.startswith('constraint'):
                continue
            
            # Extract column name (first word before space or comma)
            col_match = re.match(r'(\w+)\s+', line)
            if col_match:
                col_name = col_match.group(1).lower()
                # Avoid SQL keywords
                if col_name not in ['primary', 'foreign', 'key', 'constraint', 'check', 'unique', 'not', 'null']:
                    schema_dict[table_name].append(col_name)
    
    return schema_dict


def tokenize_simple(text):
    """Simple word tokenization"""
    text = re.sub(r'[^\w\s]', ' ', text)
    return text.lower().split()


def is_meaningful_phrase(phrase, min_content_words=1):
    """
    Checks if a phrase is meaningful for schema linking.
    
    Criteria:
    - Must have at least min_content_words content words
    - Cannot be only stopwords or generic words
    - Must have at least 2 words total
    - Cannot be only numbers/dates
    """
    # Stopwords and very generic words
    stopwords = {
        'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'as',
        'is', 'are', 'was', 'were', 'be', 'been', 'being', 'this', 'that', 'these',
        'those', 'must', 'can', 'will', 'shall', 'may', 'might', 'should', 'would',
        'and', 'or', 'but', 'if', 'then', 'than', 'such', 'which', 'who', 'whom',
        'text', 'values', 'parameters', 'defined', 'generated', 'used', 'selected',
        'within', 'having', 'given', 'only'
    }
    
    words = phrase.split()
    
    # Minimum 2 words
    if len(words) < 2:
        return False
    
    # Reject phrases that are only numbers/dates
    if re.match(r'^[\d\s\-\.]+$', phrase):
        return False
    
    # Count content words (non-stopwords)
    content_words = [w for w in words if w not in stopwords]
    
    if len(content_words) < min_content_words:
        return False
    
    # Reject phrases that start or end with generic stopwords
    if words[0] in {'must', 'be', 'is', 'are', 'the', 'a', 'an'}:
        return False
    
    return True


def extract_key_phrases(description, max_length=4):
    """
    Extracts most relevant key phrases from description.
    
    Strategy:
    1. Prioritize bigrams and trigrams over unigrams
    2. Filter generic phrases
    3. Prioritize phrases with SQL/DB related words
    """
    words = tokenize_simple(description)
    
    # Generate n-grams of different sizes
    phrases = []
    
    # Bigrams (most important)
    for i in range(len(words) - 1):
        bigram = ' '.join(words[i:i+2])
        if is_meaningful_phrase(bigram):
            phrases.append(bigram)
    
    # Trigrams
    for i in range(len(words) - 2):
        trigram = ' '.join(words[i:i+3])
        if is_meaningful_phrase(trigram, min_content_words=2):
            phrases.append(trigram)
    
    # 4-grams (more selective)
    for i in range(len(words) - 3):
        fourgram = ' '.join(words[i:i+4])
        if is_meaningful_phrase(fourgram, min_content_words=2):
            phrases.append(fourgram)
    
    # Domain keywords for TPC-C (adapted from TPC-H)
    domain_keywords = {
        'warehouse', 'district', 'customer', 'order', 'item', 'stock', 'history',
        'delivery', 'payment', 'quantity', 'amount', 'price', 'balance', 'credit',
        'date', 'timestamp', 'carrier', 'status', 'total', 'sum', 'count', 'ytd',
        'line', 'new', 'supplier', 'supply', 'street', 'city', 'state', 'zip',
        'phone', 'name', 'data', 'discount', 'tax', 'since'
    }
    
    # Prioritize phrases with domain words
    domain_phrases = [p for p in phrases if any(kw in p for kw in domain_keywords)]
    other_phrases = [p for p in phrases if p not in domain_phrases]
    
    # Combine: domain phrases first
    return domain_phrases + other_phrases


# === LOADING ===

print("📚 Loading sentence embeddings model...")
sentence_encoder = SentenceTransformer(plm_model)

print("📄 Reading schema...")
with open(schema_file, 'r', encoding='utf-8') as f:
    schema_text = f.read()

schema_dict = parse_schema(schema_text)
print(f"✅ Schema parsed: {len(schema_dict)} tables found")
for table, cols in schema_dict.items():
    print(f"   - {table}: {len(cols)} columns")

# === PROCESS QUERIES ===

description_files = [f for f in os.listdir(descriptions_dir) if f.endswith('_description.txt')]

for i, desc_file in enumerate(sorted(description_files)):
    query_name = desc_file.replace('_description.txt', '')
    
    description_path = os.path.join(descriptions_dir, desc_file)
    sql_path = os.path.join(queries_dir, f"{query_name}.sql")
    
    if not os.path.exists(sql_path):
        print(f"⚠️  SQL not found for {query_name}, skipping...")
        continue
    
    print(f'\n🔄 Generating CoT for {query_name} ({i+1}/{len(description_files)})...')
    
    # Read files
    with open(description_path, 'r', encoding='utf-8') as f:
        description = f.read().strip()
    
    with open(sql_path, 'r', encoding='utf-8') as f:
        sql_query = f.read().strip()
    
    # Extract information from SQL and description
    tables = extract_tables_from_sql(sql_query, schema_dict)
    columns = extract_columns_from_sql(sql_query, tables, schema_dict)
    
    # Extract values from both SQL and description
    sql_values = extract_values_from_sql(sql_query)
    desc_values = extract_values_from_description(description)
    
    # Only keep values that appear in BOTH SQL and description
    values = sql_values.intersection(desc_values)
    
    print(f"  📊 Tables: {tables}")
    print(f"  📋 Columns: {len(columns)} found")
    print(f"  💎 Values in SQL: {len(sql_values)}, in Description: {len(desc_values)}, Common: {len(values)}")
    if sql_values - values:
        print(f"     ℹ️  SQL-only values (ignored): {sorted(sql_values - values)}")
    if desc_values - values:
        print(f"     ℹ️  Description-only values (ignored): {sorted(desc_values - values)}")
    
    # Extract improved key phrases
    phrases = extract_key_phrases(description)
    
    print(f"  🔤 Generating embeddings for {len(phrases)} phrases...")
    phrase_encodings = sentence_encoder.encode(
        phrases,
        batch_size=batch_size,
        show_progress_bar=False,
        normalize_embeddings=True,
        convert_to_tensor=True,
        device=device
    ).cpu().tolist()
    
    # Create list of schema items
    schema_items = []
    
    # Add all columns
    for column in sorted(columns):
        schema_items.append((column, 'column'))
    
    # Add tables without referenced columns
    for table in sorted(tables):
        has_columns = any(table in col for col in columns)
        if not has_columns:
            schema_items.append((table, 'table'))
    
    # Schema linking with threshold
    schema_linkings = {}
    
    print(f"  🔗 Performing schema linking for {len(schema_items)} items...")
    for schema_item in schema_items:
        encoding = sentence_encoder.encode(
            schema_item[0],
            batch_size=1,
            show_progress_bar=False,
            normalize_embeddings=True,
            convert_to_tensor=True,
            device=device
        ).cpu().tolist()
        
        scores = util.cos_sim(encoding, phrase_encodings).squeeze(0).tolist()
        best_idx = max(enumerate(scores), key=lambda x: x[1])[0]
        best_score = scores[best_idx]
        
        # Apply similarity threshold
        if best_score < MIN_SIMILARITY_THRESHOLD:
            print(f"    ⚠️  Ignoring weak match: {schema_item[0]} -> '{phrases[best_idx]}' (score: {best_score:.3f})")
            continue
        
        phrase = phrases[best_idx]
        
        if phrase not in schema_linkings:
            schema_linkings[phrase] = {'table': [], 'column': [], 'scores': []}
        
        schema_linkings[phrase][schema_item[1]].append(schema_item[0])
        schema_linkings[phrase]['scores'].append(best_score)
    
    # Generate CoT
    cot = "Let's think step by step.\n"
    
    for phrase in sorted(schema_linkings.keys()):
        cot += f'According to "{phrase}",'
        
        if schema_linkings[phrase]['table']:
            cot += f' tables [{", ".join(sorted(schema_linkings[phrase]["table"]))}]'
        
        if schema_linkings[phrase]['column']:
            if cot.endswith(']'):
                cot += ' and'
            cot += f' columns [{", ".join(sorted(schema_linkings[phrase]["column"]))}]'
        
        cot += ' may be used.\n'
    
    if values:
        cot += f'Values [{", ".join(sorted(values))}] may be used.\n'
    
    cot += 'So the final answer is:'
    
    # Save in TXT format
    output_path = os.path.join(output_dir, f"{query_name}_cot.txt")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(f"QUESTION:\n{description}\n\n")
        f.write(f"CHAIN OF THOUGHT:\n{cot}\n\n")
        f.write(f"SQL QUERY:\n{sql_query}\n")
    
    print(f"  ✅ Saved at: {output_path}")

print(f"\n🎉 Complete! {len(description_files)} files processed in '{output_dir}/'")