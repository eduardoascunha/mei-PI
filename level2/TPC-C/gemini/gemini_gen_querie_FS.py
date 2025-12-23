import os
import numpy as np
import pickle
import google.generativeai as genai
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv


# === CONFIGURATION ===
schema_file = "../schema.txt"
descriptions_dir = "../transaction_descriptions"  
fewshot_dir = "../few_shot_examples"
queries_dir = "../original_transactions/functions"
outputs_dir = "results_FS2E_06"

# Gemini model
model_name = "gemini-2.5-pro"

# MMR configuration
NUM_EXAMPLES = 2        # Number of examples to select via MMR
MMR_LAMBDA = 0.6        # Balance: 0.6 = 60% similarity, 40% diversity

# Embeddings cache
CACHE_FILE = "embeddings_cache.pkl"
EMBEDDING_MODEL = 'BAAI/bge-small-en-v1.5'

# Load environment
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "YOUR_API_KEY_HERE")
os.makedirs(outputs_dir, exist_ok=True)

# Configure Gemini
genai.configure(api_key=GEMINI_API_KEY)


# === SYSTEM INSTRUCTION ===
SYSTEM_INSTRUCTION = """
You are a PostgreSQL expert specializing in transactional workloads.
Using the database schema and the transaction description provided, generate a valid PostgreSQL stored function that implements the transaction.
The examples below show SQL patterns, but DO NOT copy them literally.
Analyze the current question independently and create the most appropriate transaction.


Requirements:
- Create a PostgreSQL function using CREATE OR REPLACE FUNCTION syntax
- Include all necessary input and output parameters
- Implement the complete transaction logic as described
- Use RETURNS TABLE(...) ONLY when returning multiple rows of data
- NEVER mix OUT parameters with non-table return types
- Always qualify column names with table aliases in JOINs (e.g., w.w_name, not just w_name)
- Avoid ambiguous column references
- Use PL/pgSQL language
- Return ONLY the SQL code without any markdown formatting or explanations
- The function should be ready to execute in PostgreSQL
- Ensure all foreign key constraints are respected; do not insert invalid references.
- Validate input IDs (e.g., item IDs, warehouse IDs) and handle invalid or null values appropriately.
- Order inserts or updates consistently to avoid deadlocks when required.
- Respect the inputs and outputs parameters, respect foreign key constraints, careful with ambiguous references for columns and tables
- Implement proper locking and process operations in a consistent order to prevent deadlocks in high-concurrency environments.

Format: Return the complete CREATE OR REPLACE FUNCTION statement.
"""


def load_schema():
    """Load database schema"""
    with open(schema_file, "r") as f:
        return f.read()


def load_example(query_name):
    """Load description and SQL for a given query"""
    desc_path = os.path.join(fewshot_dir, f"{query_name}_description.txt")
    sql_path = os.path.join(queries_dir, f"{query_name}.sql")
    
    if not os.path.exists(desc_path) or not os.path.exists(sql_path):
        return None
    
    with open(desc_path, "r") as f:
        description = f.read().strip()
    
    with open(sql_path, "r") as f:
        sql = f.read().strip()
    
    return {"description": description, "sql": sql}


def load_or_build_embeddings_cache(embedder, query_pool):
    """Load cached embeddings or build them if needed"""
    
    if os.path.exists(CACHE_FILE):
        print("📦 Loading cached embeddings...")
        with open(CACHE_FILE, 'rb') as f:
            cache = pickle.load(f)
        
        # Verify cache integrity
        if (cache.get('model') == EMBEDDING_MODEL and 
            cache.get('dimension') == embedder.get_sentence_embedding_dimension()):
            print(f"✅ Cache loaded: {len(cache['embeddings'])} examples\n")
            return cache['embeddings']
        else:
            print("⚠️  Cache outdated, rebuilding...\n")
    
    print("🔨 Building embeddings cache...")
    embeddings = {}
    
    for example_name in query_pool:
        example = load_example(example_name)
        if example:
            emb = embedder.encode(example['description'], convert_to_tensor=False)
            embeddings[example_name] = {
                'embedding': emb,
                'description': example['description'],
                'sql': example['sql']
            }
            print(f"   ✓ {example_name}")
        else:
            print(f"   ✗ {example_name} (not found)")
    
    # Save cache
    cache = {
        'model': EMBEDDING_MODEL,
        'dimension': embedder.get_sentence_embedding_dimension(),
        'embeddings': embeddings
    }
    
    with open(CACHE_FILE, 'wb') as f:
        pickle.dump(cache, f)
    
    print(f"✅ Cache built and saved: {len(embeddings)} examples\n")
    return embeddings


def select_examples_mmr(current_description, embeddings_cache, embedder, current_query_name):
    """
    Select examples using MMR (Maximal Marginal Relevance).
    Balances similarity to query with diversity among selected examples.
    
    Args:
        current_description: The description of the current query
        embeddings_cache: Dictionary with cached embeddings
        embedder: SentenceTransformer model
        current_query_name: Name of current query to exclude
    
    Returns:
        List of selected examples sorted by relevance
    """
    
    # Encode current query
    query_embedding = embedder.encode(current_description, convert_to_tensor=False)
    query_embedding = query_embedding / np.linalg.norm(query_embedding)
    
    # Prepare candidates (exclude current query)
    candidates = []
    candidate_embeddings = []
    
    for query_name, data in embeddings_cache.items():
        if query_name == current_query_name:
            continue
        
        candidates.append({
            'name': query_name,
            'description': data['description'],
            'sql': data['sql']
        })
        
        emb = data['embedding'] / np.linalg.norm(data['embedding'])
        candidate_embeddings.append(emb)
    
    if not candidates:
        return []
    
    candidate_embeddings = np.array(candidate_embeddings)
    
    # Calculate similarities to query
    similarities_to_query = np.dot(candidate_embeddings, query_embedding)
    
    # MMR selection
    selected_indices = []
    remaining_indices = list(range(len(candidates)))
    
    for _ in range(min(NUM_EXAMPLES, len(candidates))):
        if not remaining_indices:
            break
        
        best_idx = None
        best_score = float('-inf')
        
        for idx in remaining_indices:
            # Relevance: similarity to query
            relevance = similarities_to_query[idx]
            
            # Redundancy: max similarity to already selected examples
            if selected_indices:
                selected_embs = candidate_embeddings[selected_indices]
                
                # Ensure selected_embs is always 2D
                if selected_embs.ndim == 1:
                    selected_embs = selected_embs.reshape(1, -1)
                
                # Calculate similarities to all selected examples
                similarities_to_selected = np.dot(
                    candidate_embeddings[idx],
                    selected_embs.T
                )
                
                redundancy = np.max(similarities_to_selected)
            else:
                redundancy = 0
            
            # MMR score: balance relevance and diversity
            mmr_score = MMR_LAMBDA * relevance - (1 - MMR_LAMBDA) * redundancy
            
            if mmr_score > best_score:
                best_score = mmr_score
                best_idx = idx
        
        if best_idx is not None:
            selected_indices.append(best_idx)
            remaining_indices.remove(best_idx)
    
    # Build results with similarity scores (sorted by relevance)
    selected = []
    for idx in selected_indices:
        selected.append({
            'name': candidates[idx]['name'],
            'description': candidates[idx]['description'],
            'sql': candidates[idx]['sql'],
            'similarity': float(similarities_to_query[idx])
        })
    
    # Sort by similarity (most relevant first)
    selected.sort(key=lambda x: x['similarity'], reverse=True)
    
    return selected


def build_few_shot_prompt(schema, examples, question):
    """Build the complete few-shot prompt"""
    
    prompt = f"DATABASE SCHEMA:\n{schema}\n\n"
    
    if examples:
        prompt += "Here are some examples of questions and their corresponding SQL queries:\n\n"
        
        for i, ex in enumerate(examples, 1):
            prompt += f"--- Example {i} ---\n"
            prompt += f"QUESTION:\n{ex['description']}\n\n"
            prompt += f"SQL QUERY:\n{ex['sql']}\n\n"
    
    prompt += "--- Your Task ---\n"
    prompt += f"QUESTION:\n{question}\n\n"
    prompt += "SQL QUERY:\n"
    
    return prompt


def generate_sql(schema, question, examples):
    """Generate SQL using Gemini with few-shot examples"""
    
    prompt = build_few_shot_prompt(schema, examples, question)
    
    try:
        # Create model with system instruction
        model = genai.GenerativeModel(
            model_name=model_name,
            system_instruction=SYSTEM_INSTRUCTION.strip()
        )
        
        # Generate content
        response = model.generate_content(
            prompt.strip(),
            generation_config=genai.GenerationConfig(
                temperature=0.0,
            )
        )
        
        sql = response.text.strip()
        
        # Clean markdown formatting
        if sql.startswith("```sql"):
            sql = sql[6:]
        if sql.startswith("```"):
            sql = sql[3:]
        if sql.endswith("```"):
            sql = sql[:-3]
        
        return sql.strip()
        
    except Exception as e:
        raise Exception(f"Gemini API Error: {str(e)}")


# === MAIN EXECUTION ===

def main():
    print("=" * 70)
    print("🚀 FEW-SHOT SQL GENERATOR WITH MMR (GEMINI)")
    print("=" * 70)
    
    # Load schema
    print("\n📄 Loading schema...")
    schema = load_schema()
    print("✅ Schema loaded\n")
    
    # Initialize embedder
    print(f"🔄 Loading embedding model ({EMBEDDING_MODEL})...")
    embedder = SentenceTransformer(EMBEDDING_MODEL)
    print("✅ Embedding model loaded\n")
    
    # Get all available queries for the pool
    all_queries = set()
    for filename in os.listdir(fewshot_dir):
        if filename.endswith("_description.txt"):
            query_name = filename.replace("_description.txt", "")
            all_queries.add(query_name)
    
    print(f"📋 Total queries in pool: {len(all_queries)}\n")
    
    # Build embeddings cache for all queries
    embeddings_cache = load_or_build_embeddings_cache(embedder, all_queries)
    
    # Configuration summary
    print(f"📊 Configuration:")
    print(f"   - Model: {model_name}")
    print(f"   - Examples per query: {NUM_EXAMPLES} (selected via MMR)")
    print(f"   - MMR lambda: {MMR_LAMBDA} (higher = more similarity, lower = more diversity)")
    print(f"   - Embedding model: {EMBEDDING_MODEL}")
    print(f"   - Output directory: {outputs_dir}\n")
    print("=" * 70 + "\n")
    
    # Process all descriptions
    processed = 0
    errors = 0
    
    for filename in sorted(os.listdir(descriptions_dir)):
        if not filename.endswith("_description.txt"):
            continue
        
        query_name = filename.replace("_description.txt", "")
        description_path = os.path.join(descriptions_dir, filename)
        
        with open(description_path, "r") as f:
            description_text = f.read().strip()
        
        print(f"🚀 Processing: {query_name}")
        
        # Select examples via MMR
        selected_examples = select_examples_mmr(
            description_text,
            embeddings_cache,
            embedder,
            query_name
        )
        
        if not selected_examples:
            print(f"   ⚠️  No examples available for this query!\n")
            errors += 1
            continue
        
        print(f"   🎯 Selected {len(selected_examples)} examples (sorted by relevance):")
        for ex in selected_examples:
            print(f"      - {ex['name']} (similarity: {ex['similarity']:.3f})")
        
        # Generate SQL
        print(f"   🧠 Generating SQL...")
        try:
            sql_query = generate_sql(schema, description_text, selected_examples)
        except Exception as e:
            print(f"   ❌ Error: {e}\n")
            errors += 1
            continue
        
        # Save output
        output_path = os.path.join(outputs_dir, f"{query_name}.sql")
        with open(output_path, "w") as f:
            f.write(sql_query)
        
        print(f"   ✅ Saved to: {output_path}")
        
        # Preview
        preview = sql_query[:150].replace('\n', ' ')
        if len(sql_query) > 150:
            preview += "..."
        print(f"   📝 Preview: {preview}\n")
        
        processed += 1
    
    print("=" * 70)
    print(f"✨ Processing complete!")
    print(f"   - Successful: {processed}")
    print(f"   - Errors: {errors}")
    print("=" * 70)


if __name__ == "__main__":
    main()