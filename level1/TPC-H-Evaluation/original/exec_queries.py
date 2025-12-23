import os
import subprocess
import re

DB_NAME = "tpch"
QUERY_DIR = "./queries"
OUTPUT_DIR = "./answers"

os.makedirs(OUTPUT_DIR, exist_ok=True)

def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split(r'(\d+)', s)]

for filename in sorted(os.listdir(QUERY_DIR), key=natural_sort_key):
    if filename.endswith(".sql"):
        base = filename[:-4]
        input_path = os.path.join(QUERY_DIR, filename)
        output_path = os.path.join(OUTPUT_DIR, f"{base}.output.txt")

        print(f"▶️ Executando {filename}...")
        with open(output_path, "w") as outfile:
            subprocess.run(["psql", "-d", DB_NAME, "-f", input_path],
                           stdout=outfile, stderr=subprocess.STDOUT)

        print(f"✅ Resultado guardado em {output_path}")

print("🎉 Todas as queries foram executadas com sucesso!")
