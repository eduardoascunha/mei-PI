import os
import pandas as pd
import numpy as np
from pathlib import Path
import re


def parse_psql_output(file_path):
    """
    Parse PostgreSQL output format (table with | separators)
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Remove empty lines and strip whitespace
    lines = [line.strip() for line in lines if line.strip()]
    
    if len(lines) < 3:
        return None
    
    # Find header line (contains column names)
    header_idx = 0
    for i, line in enumerate(lines):
        if '|' in line and not set(line.replace('|', '').strip()) == {'-', '+'}:
            header_idx = i
            break
    
    # Parse header
    header_line = lines[header_idx]
    columns = [col.strip() for col in header_line.split('|')]
    columns = [col for col in columns if col]  # Remove empty strings
    
    # Find data lines (skip separator lines with -----)
    data_lines = []
    for line in lines[header_idx + 1:]:
        # Skip separator lines and footer (e.g., "(4 rows)")
        if '---' in line or 'row' in line.lower() or not '|' in line:
            continue
        data_lines.append(line)
    
    # Parse data
    data = []
    for line in data_lines:
        values = [val.strip() for val in line.split('|')]
        values = [val for val in values if val]  # Remove empty strings
        if len(values) == len(columns):
            data.append(values)
    
    if not data:
        return None
    
    # Create DataFrame
    df = pd.DataFrame(data, columns=columns)
    
    # Convert numeric columns
    for col in df.columns:
        try:
            # Try to convert to numeric
            df[col] = pd.to_numeric(df[col])
        except:
            # Keep as string if conversion fails
            pass
    
    return df


def match_columns_by_content(df1, df2):
    """
    Match columns between two DataFrames based on their content similarity.
    Returns mapping from df2 columns to df1 columns, or None if no good match.
    """
    if df1.shape != df2.shape:
        return None
    
    if df1.shape[1] == 0:
        return {}
    
    # Try to match columns by data type and values
    col_mapping = {}
    used_cols = set()
    
    for col1 in df1.columns:
        best_match = None
        best_score = 0
        
        for col2 in df2.columns:
            if col2 in used_cols:
                continue
            
            # Check if same data type
            is_numeric1 = pd.api.types.is_numeric_dtype(df1[col1])
            is_numeric2 = pd.api.types.is_numeric_dtype(df2[col2])
            
            if is_numeric1 != is_numeric2:
                continue
            
            # Calculate similarity score
            score = 0
            
            if is_numeric1:
                # For numeric columns, check if values are close
                try:
                    if np.allclose(df1[col1], df2[col2], rtol=1e-6, atol=1e-6, equal_nan=True):
                        score = 1.0
                except:
                    pass
            else:
                # For string columns, check exact match
                if df1[col1].equals(df2[col2]):
                    score = 1.0
            
            if score > best_score:
                best_score = score
                best_match = col2
        
        if best_match and best_score > 0.99:  # High threshold for matching
            col_mapping[best_match] = col1
            used_cols.add(best_match)
        else:
            # No good match found
            return None
    
    # Check if all columns were mapped
    if len(col_mapping) != df2.shape[1]:
        return None
    
    return col_mapping


def compare_dataframes(df1, df2, float_tolerance=1e-6):
    """
    Compare two DataFrames with intelligent column matching and tolerance for floating point numbers.
    Ignores column names and matches by content.
    """
    if df1 is None or df2 is None:
        return False, "One or both DataFrames are None"
    
    # Check if same shape
    if df1.shape != df2.shape:
        return False, f"Different shapes: {df1.shape} vs {df2.shape}"
    
    # Try to match columns by content
    col_mapping = match_columns_by_content(df1, df2)
    
    if col_mapping is None:
        return False, "Could not match columns by content"
    
    # Reorder df2 columns to match df1
    df2_reordered = df2.rename(columns=col_mapping)[df1.columns]
    
    # Sort both DataFrames by all columns for comparison
    try:
        df1_sorted = df1.sort_values(by=list(df1.columns), ignore_index=True)
        df2_sorted = df2_reordered.sort_values(by=list(df2_reordered.columns), ignore_index=True)
    except:
        # If sorting fails, compare as-is
        df1_sorted = df1.reset_index(drop=True)
        df2_sorted = df2_reordered.reset_index(drop=True)
    
    # Compare each column
    for col in df1_sorted.columns:
        col1 = df1_sorted[col]
        col2 = df2_sorted[col]
        
        # Check if numeric
        if pd.api.types.is_numeric_dtype(col1) and pd.api.types.is_numeric_dtype(col2):
            # Use numpy allclose for float comparison
            if not np.allclose(col1, col2, rtol=float_tolerance, atol=float_tolerance, equal_nan=True):
                return False, f"Numeric values differ in matched columns"
        else:
            # String comparison
            if not col1.equals(col2):
                return False, f"String values differ in matched columns"
    
    return True, "Match (content-based column mapping)"


def evaluate_execution_accuracy(original_dir, generated_dir, output_file='evaluation_results.txt'):
    """
    Evaluate Execution Accuracy for TPC-H queries
    
    Args:
        original_dir: Directory with original outputs (q1.output.txt, q2.output.txt, ...)
        generated_dir: Directory with LLM generated outputs (q1_ZS.output.txt, ...)
        output_file: File to save detailed results
    """
    original_path = Path(original_dir)
    generated_path = Path(generated_dir)
    
    results = []
    correct_count = 0
    total_count = 0
    
    # Find all original output files
    original_files = sorted(original_path.glob('q*.output.txt'))
    
    print(f"Found {len(original_files)} original query outputs\n")
    print("="*80)
    
    for orig_file in original_files:
        # Extract query number (e.g., q1 from q1.output.txt)
        query_num = orig_file.stem.replace('.output', '')
        
        # Find corresponding generated file (q1_ZS.output.txt or similar)
        gen_files = list(generated_path.glob(f'{query_num}_*.output.txt'))
        
        if not gen_files:
            print(f"❌ {query_num}: No generated output found")
            results.append({
                'query': query_num,
                'status': 'MISSING',
                'match': False,
                'reason': 'No generated output file found'
            })
            total_count += 1
            continue
        
        # Use the first matching file
        gen_file = gen_files[0]
        total_count += 1
        
        try:
            # Parse both files
            df_orig = parse_psql_output(orig_file)
            df_gen = parse_psql_output(gen_file)
            
            if df_orig is None:
                print(f"⚠️  {query_num}: Could not parse original output")
                results.append({
                    'query': query_num,
                    'status': 'PARSE_ERROR_ORIG',
                    'match': False,
                    'reason': 'Failed to parse original output'
                })
                continue
            
            if df_gen is None:
                print(f"⚠️  {query_num}: Could not parse generated output")
                results.append({
                    'query': query_num,
                    'status': 'PARSE_ERROR_GEN',
                    'match': False,
                    'reason': 'Failed to parse generated output'
                })
                continue
            
            # Compare with intelligent column matching
            is_match, reason = compare_dataframes(df_orig, df_gen)
            
            if is_match:
                print(f"✅ {query_num}: MATCH")
                print(f"   Original cols: {list(df_orig.columns)}")
                print(f"   Generated cols: {list(df_gen.columns)}")
                correct_count += 1
                results.append({
                    'query': query_num,
                    'status': 'MATCH',
                    'match': True,
                    'orig_shape': df_orig.shape,
                    'gen_shape': df_gen.shape,
                    'orig_cols': list(df_orig.columns),
                    'gen_cols': list(df_gen.columns),
                    'reason': reason
                })
            else:
                print(f"❌ {query_num}: MISMATCH - {reason}")
                print(f"   Original shape: {df_orig.shape}, Generated shape: {df_gen.shape}")
                print(f"   Original columns: {list(df_orig.columns)}")
                print(f"   Generated columns: {list(df_gen.columns)}")
                results.append({
                    'query': query_num,
                    'status': 'MISMATCH',
                    'match': False,
                    'orig_shape': df_orig.shape,
                    'gen_shape': df_gen.shape,
                    'orig_cols': list(df_orig.columns),
                    'gen_cols': list(df_gen.columns),
                    'reason': reason
                })
        
        except Exception as e:
            print(f"❌ {query_num}: ERROR - {str(e)}")
            results.append({
                'query': query_num,
                'status': 'ERROR',
                'match': False,
                'error': str(e)
            })
    
    # Calculate metrics
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)
    execution_accuracy = (correct_count / total_count * 100) if total_count > 0 else 0
    print(f"Execution Accuracy (EX): {execution_accuracy:.2f}%")
    print(f"Correct: {correct_count}/{total_count}")
    
    # Additional stats
    missing_count = sum(1 for r in results if r['status'] == 'MISSING')
    parse_errors = sum(1 for r in results if 'PARSE_ERROR' in r['status'])
    mismatch_count = sum(1 for r in results if r['status'] == 'MISMATCH')
    
    print(f"\nBreakdown:")
    print(f"  ✅ Correct matches: {correct_count}")
    print(f"  ❌ Mismatches: {mismatch_count}")
    print(f"  ⚠️  Missing outputs: {missing_count}")
    print(f"  ⚠️  Parse errors: {parse_errors}")
    
    # Save detailed results
    with open(output_file, 'w') as f:
        f.write("TPC-H Execution Accuracy Evaluation\n")
        f.write("="*80 + "\n\n")
        f.write(f"Execution Accuracy (EX): {execution_accuracy:.2f}%\n")
        f.write(f"Correct: {correct_count}/{total_count}\n\n")
        f.write(f"Breakdown:\n")
        f.write(f"  Correct matches: {correct_count}\n")
        f.write(f"  Mismatches: {mismatch_count}\n")
        f.write(f"  Missing outputs: {missing_count}\n")
        f.write(f"  Parse errors: {parse_errors}\n\n")
        f.write("Detailed Results:\n")
        f.write("-"*80 + "\n")
        
        for result in results:
            f.write(f"\nQuery: {result['query']}\n")
            f.write(f"Status: {result['status']}\n")
            f.write(f"Match: {result['match']}\n")
            if 'reason' in result:
                f.write(f"Reason: {result['reason']}\n")
            if 'orig_shape' in result:
                f.write(f"Original shape: {result['orig_shape']}\n")
                f.write(f"Generated shape: {result['gen_shape']}\n")
            if 'orig_cols' in result:
                f.write(f"Original columns: {result['orig_cols']}\n")
                f.write(f"Generated columns: {result['gen_cols']}\n")
            if 'error' in result:
                f.write(f"Error: {result['error']}\n")
            f.write("-"*80 + "\n")
    
    print(f"\nDetailed results saved to: {output_file}")
    
    return execution_accuracy, results


if __name__ == "__main__":
    # Example usage
    original_dir = "original/answers"
    generated_dir = "generated_sql/answers"
    
    # Run evaluation
    accuracy, results = evaluate_execution_accuracy(
        original_dir, 
        generated_dir,
        output_file='tpch_evaluation_results.txt'
    )
    
    print(f"\n🎯 Final Execution Accuracy: {accuracy:.2f}%")