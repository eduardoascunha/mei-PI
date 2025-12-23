import os
import subprocess
import re
import csv


DB_NAME = "tpch"

QUERY_DIR = "deepseek/results_FS5E_04"
OUTPUT_DIR = "deepseek/results_FS5E_04/answers"

"""
QUERY_DIR = "./original_queries/queries"
OUTPUT_DIR = "./original_queries/answers"
"""

TIMING_CSV = os.path.join(OUTPUT_DIR, "query_execution_times.csv")

os.makedirs(OUTPUT_DIR, exist_ok=True)

def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split(r'(\d+)', s)]

def extract_timing_from_output(output_text):
    """Extract execution time from psql output with \\timing"""
    # Search for "Time: X ms" or "Time: X,Y ms" (PT format with comma)
    match = re.search(r'Time:\s+([\d,\.]+)\s+ms', output_text)
    if match:
        time_str = match.group(1).replace(',', '.')  # Replace comma with dot
        return float(time_str) / 1000.0  # Convert to seconds
    return None

# Prepare CSV to save execution times
with open(TIMING_CSV, "w", newline='', encoding='utf-8') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(["Query", "Execution_Time_Seconds"])

    for filename in sorted(os.listdir(QUERY_DIR), key=natural_sort_key):
        if filename.endswith(".sql"):
            base = filename[:-4]  # remove ".sql"
            input_path = os.path.join(QUERY_DIR, filename)
            output_path = os.path.join(OUTPUT_DIR, f"{base}.output.txt")

            print(f"▶️ Executing {filename}...")
            
            # Execute with \timing enabled to measure actual query time
            result = subprocess.run(
                ["psql", "-d", DB_NAME, "-c", "\\timing", "-f", input_path],
                capture_output=True,
                text=True
            )
            
            # Combine stdout and stderr
            full_output = result.stdout + result.stderr
            
            # Extract execution time before cleaning
            execution_time = extract_timing_from_output(full_output)
            
            # Remove timing-related lines from output file
            clean_output = full_output
            clean_output = re.sub(r'^Timing is on\.\n?', '', clean_output, flags=re.MULTILINE)
            clean_output = re.sub(r'^Time:.*\n?', '', clean_output, flags=re.MULTILINE)
            
            # Save clean output to file
            with open(output_path, "w") as outfile:
                outfile.write(clean_output)
            
            if execution_time is not None:
                csv_writer.writerow([filename, f"{execution_time:.6f}"])
                print(f"✅ Result saved to {output_path}")
                print(f"⏱️  Execution time: {execution_time:.3f} seconds")
            else:
                csv_writer.writerow([filename, "N/A"])
                print(f"✅ Result saved to {output_path}")
                print(f"⚠️  Could not extract execution time")

print(f"\n🎉 All queries executed successfully!")
print(f"📊 Execution times saved to {TIMING_CSV}")