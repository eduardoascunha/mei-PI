import os
import re
import math
from pathlib import Path
import pandas as pd
from io import StringIO

# =============================================================================
# CONFIGURATION
# =============================================================================

LLM_RESULTS_DIR = "deepseek/results_FS5E_04/answers"
ORIGINAL_RESULTS_DIR = "original_queries/answers"
OUTPUT_TXT_FILE = "deepseek/results_FS5E_04/evaluation_results.txt"
OUTPUT_CSV_FILE = "deepseek/results_FS5E_04/evaluation_results.csv"

# =============================================================================
"""
LLM_RESULTS_DIR = "deepseek/results_ZS/answers"
ORIGINAL_RESULTS_DIR = "original_queries/answers"
OUTPUT_TXT_FILE = "deepseek/results_ZS/evaluation_results.txt"
OUTPUT_CSV_FILE = "deepseek/results_ZS/evaluation_results.csv"
"""

def clean_sql_output(content):
    """
    Remove SQL commands and other non-data lines from output.
    """
    lines = content.strip().split('\n')
    cleaned_lines = []
    
    # SQL commands to ignore
    sql_commands = ['CREATE VIEW', 'DROP VIEW', 'CREATE TABLE', 'DROP TABLE', 
                    'INSERT INTO', 'UPDATE', 'DELETE', 'ALTER TABLE', 'BEGIN', 'COMMIT']
    
    for line in lines:
        line_stripped = line.strip()
        
        # Skip empty lines
        if not line_stripped:
            continue
        
        # Skip SQL command lines
        if any(line_stripped.upper().startswith(cmd) for cmd in sql_commands):
            continue
        
        # Skip lines with just parentheses or row counts like "(1 row)" or "(10 rows)"
        if re.match(r'^\(\d+\s+rows?\)$', line_stripped):
            continue
        
        cleaned_lines.append(line)
    
    return '\n'.join(cleaned_lines)


def parse_table_output(content):
    """
    Parse table output in text format to a DataFrame.
    Handles both multi-column (with |) and single-column tables.
    """
    # Clean the content first
    content = clean_sql_output(content)
    lines = content.strip().split('\n')
    
    if not lines:
        return None
    
    # Detect if this is a single-column table (no | separators)
    has_pipe = any('|' in line for line in lines if not re.match(r'^[\s\-|+]+$', line))
    
    if not has_pipe:
        # Single column table format
        return parse_single_column_table(lines)
    else:
        # Multi-column table format
        return parse_multi_column_table(lines)


def parse_single_column_table(lines):
    """
    Parse single-column table output (no | separators).
    """
    if not lines:
        return None
    
    # Find header line (first non-separator line)
    header_line = None
    header_idx = -1
    
    for i, line in enumerate(lines):
        line_stripped = line.strip()
        # Skip separator lines (only dashes and spaces)
        if re.match(r'^[\s\-]+$', line_stripped):
            continue
        # First non-separator line is the header
        if line_stripped:
            header_line = line_stripped
            header_idx = i
            break
    
    if header_line is None:
        return None
    
    # Column name is the header
    column_name = header_line.strip()
    
    # Find separator line (line with dashes after header)
    separator_idx = -1
    for i in range(header_idx + 1, len(lines)):
        if re.match(r'^[\s\-]+$', lines[i].strip()):
            separator_idx = i
            break
    
    # Data starts after separator
    data_start = separator_idx + 1 if separator_idx >= 0 else header_idx + 1
    
    # Parse data lines
    values = []
    for i in range(data_start, len(lines)):
        line = lines[i].strip()
        
        # Skip empty lines and separator lines
        if not line or re.match(r'^[\s\-]+$', line):
            continue
        
        # Skip row count lines like "(1 row)"
        if re.match(r'^\(\d+\s+rows?\)$', line):
            continue
        
        values.append(line)
    
    if not values:
        return None
    
    # Create DataFrame with single column
    df = pd.DataFrame(values, columns=[column_name])
    
    # Convert numeric values
    try:
        df[column_name] = pd.to_numeric(df[column_name])
    except (ValueError, TypeError):
        pass  # Keep as string if not numeric
    
    return df


def parse_multi_column_table(lines):
    """
    Parse multi-column table output (with | separators).
    """
    # Find header line (contains column names, typically has | separators)
    header_line = None
    header_idx = -1
    
    for i, line in enumerate(lines):
        # Header line typically contains | and is not a separator line (---)
        if '|' in line and not re.match(r'^[\s\-|+]+$', line):
            header_line = line
            header_idx = i
            break
    
    if header_line is None:
        return None
    
    # Extract column names
    columns = [col.strip() for col in header_line.split('|') if col.strip()]
    
    if not columns:
        return None
    
    # Find separator line (line with dashes after header)
    separator_idx = -1
    for i in range(header_idx + 1, len(lines)):
        if re.match(r'^[\s\-|+]+$', lines[i]):
            separator_idx = i
            break
    
    # Data starts after separator (if found) or after header
    data_start = separator_idx + 1 if separator_idx >= 0 else header_idx + 1
    
    # Parse data lines
    rows = []
    for i in range(data_start, len(lines)):
        line = lines[i].strip()
        
        # Skip empty lines and separator lines
        if not line or re.match(r'^[\s\-|+]+$', line):
            continue
        
        # Skip row count lines like "(1 row)"
        if re.match(r'^\(\d+\s+rows?\)$', line):
            continue
        
        # Parse data row
        if '|' in line:
            values = [val.strip() for val in line.split('|') if val.strip() or val == '']
            
            # Only add rows that have the same number of columns
            if len(values) == len(columns):
                rows.append(values)
    
    if not rows:
        return None
    
    # Create DataFrame
    df = pd.DataFrame(rows, columns=columns)
    
    # Convert numeric values
    for col in df.columns:
        try:
            df[col] = pd.to_numeric(df[col])
        except (ValueError, TypeError):
            pass  # Keep as string if not numeric
    
    return df


def normalize_value(val, tolerance=1e-6):
    """
    Normalize a value for comparison.
    For numeric values, round to tolerance decimal places.
    For strings, strip whitespace and convert to lowercase.
    """
    try:
        # Try to convert to float
        num_val = float(val)
        # Round based on tolerance (e.g., 1e-6 -> 6 decimal places)
        decimals = int(-1 * math.log10(tolerance)) if tolerance < 1 else 0
        return round(num_val, decimals)
    except (ValueError, TypeError, AttributeError):
        # Keep as string, stripped and lowercase for case-insensitive comparison
        return str(val).strip().lower()


def dataframe_to_set(df, columns_subset=None):
    """
    Convert DataFrame to a set of sorted tuples (rows) for comparison.
    Each row is converted to a sorted tuple of normalized values to ignore column order.
    If columns_subset is provided, only those columns are used.
    """
    if df is None or df.empty:
        return set()
    
    # If columns_subset is specified, filter the dataframe
    if columns_subset is not None:
        df = df[columns_subset]
    
    # Convert each row to a sorted tuple of normalized values
    rows_set = set()
    for _, row in df.iterrows():
        # Normalize all values and sort them to ignore column order
        normalized_values = [normalize_value(val) for val in row]
        # Sort to make column order irrelevant
        sorted_row = tuple(sorted(normalized_values, key=lambda x: (type(x).__name__, str(x))))
        rows_set.add(sorted_row)
    
    return rows_set


def compare_dataframes(df1, df2, tolerance=1e-6):
    """
    Compare two DataFrames as sets of rows, ignoring column names, column order, and row order.
    
    NEW BEHAVIOR: If df2 (LLM result) has MORE columns than df1 (original), we check if
    the data in df1's columns exists somewhere in df2. If yes, it's a PASS with warning.
    
    Returns (status, differences, extra_columns_count)
    status: 'PASS', 'PASS_WITH_EXTRA_COLS', or 'FAIL'
    """
    if df1 is None and df2 is None:
        return 'PASS', [], 0
    
    if df1 is None or df2 is None:
        return 'FAIL', ["One of the DataFrames is None"], 0
    
    differences = []
    extra_cols = 0
    
    # Check if LLM has more columns
    num_cols_original = df1.shape[1]
    num_cols_llm = df2.shape[1]
    
    if num_cols_llm > num_cols_original:
        extra_cols = num_cols_llm - num_cols_original
        
        # Check if the original columns' data exists in the LLM result
        # We need to find which combination of LLM columns matches the original
        
        # Strategy: try to match by comparing sets of data
        # Convert original to set
        set_original = dataframe_to_set(df1)
        
        # Try all combinations of num_cols_original columns from df2
        from itertools import combinations
        found_match = False
        
        for col_subset in combinations(df2.columns, num_cols_original):
            set_llm_subset = dataframe_to_set(df2, list(col_subset))
            
            if set_original == set_llm_subset:
                found_match = True
                break
        
        if found_match:
            # The original data exists in the LLM result, just with extra columns
            return 'PASS_WITH_EXTRA_COLS', [f"LLM returned {extra_cols} extra column(s)"], extra_cols
        else:
            # Even with extra columns, the data doesn't match
            differences.append(f"LLM has {extra_cols} extra column(s) AND data mismatch")
    
    # Standard comparison (same number of columns or LLM has fewer)
    if df1.shape != df2.shape:
        differences.append(f"Different dimensions: {df1.shape} vs {df2.shape}")
    
    # Convert to sets of rows (sorted tuples)
    set1 = dataframe_to_set(df1)
    set2 = dataframe_to_set(df2)
    
    # Find differences
    only_in_original = set1 - set2
    only_in_llm = set2 - set1
    
    if only_in_original:
        differences.append(f"Rows only in original ({len(only_in_original)}): {list(only_in_original)[:3]}")
    
    if only_in_llm:
        differences.append(f"Rows only in LLM ({len(only_in_llm)}): {list(only_in_llm)[:3]}")
    
    if len(differences) == 0:
        return 'PASS', [], 0
    else:
        return 'FAIL', differences, 0


def natural_sort_key(filename):
    """
    Generate key for natural sorting (q1, q2, ..., q10, q11, ...)
    """
    parts = re.split(r'(\d+)', str(filename))
    return [int(part) if part.isdigit() else part for part in parts]


def evaluate_results(llm_dir, original_dir, output_txt_file, output_csv_file):
    """
    Evaluate results by comparing query outputs.
    """
    llm_path = Path(llm_dir)
    original_path = Path(original_dir)
    
    results = []
    
    # List all .output.txt files in original directory with natural sorting
    original_files = sorted(original_path.glob("*.output.txt"), key=natural_sort_key)
    
    print(f"Found {len(original_files)} original files\n")
    
    for original_file in original_files:
        query_name = original_file.name
        llm_file = llm_path / query_name
        
        print(f"Evaluating {query_name}...")
        
        # Extract base query name (without .output.txt)
        query_base_name = query_name.replace('.output.txt', '')
        
        # Check if LLM file exists
        if not llm_file.exists():
            results.append({
                'query': query_name,
                'query_base': query_base_name,
                'status': 'MISSING',
                'accuracy': 0,
                'message': 'File not found in LLM directory'
            })
            print(f"  ❌ MISSING: File not found\n")
            continue
        
        # Read contents
        with open(original_file, 'r', encoding='utf-8') as f:
            original_content = f.read()
        
        with open(llm_file, 'r', encoding='utf-8') as f:
            llm_content = f.read()
        
        # Parse outputs
        df_original = parse_table_output(original_content)
        df_llm = parse_table_output(llm_content)
        
        # Debug: print shapes
        if df_original is not None and df_llm is not None:
            print(f"  Original shape: {df_original.shape}, LLM shape: {df_llm.shape}")
        
        # Compare
        status, differences, extra_cols = compare_dataframes(df_original, df_llm)
        
        if status == 'PASS':
            results.append({
                'query': query_name,
                'query_base': query_base_name,
                'status': 'PASS',
                'accuracy': 1,
                'message': 'Identical results'
            })
            print(f"  ✅ PASS\n")
        elif status == 'PASS_WITH_EXTRA_COLS':
            results.append({
                'query': query_name,
                'query_base': query_base_name,
                'status': 'PASS_WITH_EXTRA_COLS',
                'accuracy': 1,
                'message': f'Data matches but LLM returned {extra_cols} extra column(s)'
            })
            print(f"  ✅ PASS (with {extra_cols} extra column(s))\n")
        else:
            results.append({
                'query': query_name,
                'query_base': query_base_name,
                'status': 'FAIL',
                'accuracy': 0,
                'message': '\n    '.join(differences[:5])  # Show only first 5 differences
            })
            print(f"  ❌ FAIL")
            for diff in differences[:3]:
                print(f"     - {diff}")
            if len(differences) > 3:
                print(f"     ... and {len(differences) - 3} more differences")
            print()
    
    # Calculate statistics
    total = len(results)
    passed = sum(1 for r in results if r['status'] in ['PASS', 'PASS_WITH_EXTRA_COLS'])
    passed_exact = sum(1 for r in results if r['status'] == 'PASS')
    passed_extra_cols = sum(1 for r in results if r['status'] == 'PASS_WITH_EXTRA_COLS')
    failed = sum(1 for r in results if r['status'] == 'FAIL')
    missing = sum(1 for r in results if r['status'] == 'MISSING')
    
    accuracy = (passed / total * 100) if total > 0 else 0
    
    # Write CSV
    with open(output_csv_file, 'w', encoding='utf-8') as f:
        f.write("query;accuracy\n")
        for result in results:
            f.write(f"{result['query_base']};{result['accuracy']}\n")
    
    # Write report
    with open(output_txt_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("TEXT-TO-SQL EVALUATION REPORT\n")
        f.write("=" * 80 + "\n\n")
        
        f.write(f"Total queries: {total}\n")
        f.write(f"Correct (PASS): {passed} ({accuracy:.2f}%)\n")
        f.write(f"  - Exact match: {passed_exact}\n")
        f.write(f"  - With extra columns: {passed_extra_cols}\n")
        f.write(f"Incorrect (FAIL): {failed}\n")
        f.write(f"Not found (MISSING): {missing}\n\n")
        
        f.write("=" * 80 + "\n")
        f.write("DETAILS PER QUERY\n")
        f.write("=" * 80 + "\n\n")
        
        for result in results:
            f.write(f"Query: {result['query']}\n")
            f.write(f"Status: {result['status']}\n")
            if result['status'] != 'PASS':
                f.write(f"Details:\n    {result['message']}\n")
            f.write("-" * 80 + "\n\n")
    
    print("=" * 80)
    print(f"EVALUATION SUMMARY")
    print("=" * 80)
    print(f"Total: {total} | PASS: {passed} ({accuracy:.2f}%) | FAIL: {failed} | MISSING: {missing}")
    print(f"  - Exact match: {passed_exact}")
    print(f"  - With extra columns: {passed_extra_cols}")
    print(f"\nFull report saved to: {output_txt_file}")
    print(f"CSV results saved to: {output_csv_file}")
    
    return results, accuracy


# Run evaluation
if __name__ == "__main__":
    results, accuracy = evaluate_results(
        LLM_RESULTS_DIR,
        ORIGINAL_RESULTS_DIR,
        OUTPUT_TXT_FILE,
        OUTPUT_CSV_FILE
    )