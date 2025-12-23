import os
import requests
from dotenv import load_dotenv

# === CONFIG ===
schema_file = "../schema.txt"
descriptions_dir = "../transaction_descriptions"  
outputs_dir = "results_ZS_R"

# choose the model available on OpenRouter
model_name = "meta-llama/llama-4-maverick"

# Load OpenRouter API key
load_dotenv()
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "YOUR_API_KEY_HERE")

os.makedirs(outputs_dir, exist_ok=True)

# === System instruction ===
instruction = """
You are a PostgreSQL expert specializing in transactional workloads.
Using the database schema and the transaction description provided, generate a valid PostgreSQL stored function that implements the transaction.

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
- RESPECT THE INPUTS AND OUTPUTS PARAMETERS, RESPECT FOREIGN KEY CONSTRAINTS, CAREFUL WITH AMBIGUOUS REFERENCES FOR COLUMNS AND TABLES

Format: Return the complete CREATE OR REPLACE FUNCTION statement.
Let's think step by step!
"""

# === Read schema ===
with open(schema_file, "r") as f:
    schema_text = f.read()


def generate_sql(schema, question):
    prompt = f"""
DATABASE SCHEMA:
{schema}

TRANSACTION DESCRIPTION:
[{question}]
"""
    print("🧠 Sending request to OpenRouter...")
    
    try:
        headers = {
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": model_name,
            "messages": [
                {"role": "system", "content": instruction.strip()},
                {"role": "user", "content": prompt.strip()},
            ],
            "temperature": 0.0,
        }

        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=120,
        )

        if response.status_code != 200:
            raise Exception(f"API Error {response.status_code}: {response.text}")

        data = response.json()
        sql = data["choices"][0]["message"]["content"].strip()

        # Clean output (remove markdown if present)
        if sql.startswith("```sql"):
            sql = sql[6:]
        if sql.startswith("```"):
            sql = sql[3:]
        if sql.endswith("```"):
            sql = sql[:-3]
        
        sql = sql.strip()
        return sql
        
    except Exception as e:
        raise Exception(f"OpenRouter API Error: {str(e)}")


# === Process all descriptions ===
description_files = [f for f in os.listdir(descriptions_dir) if f.endswith("_description.txt")]

if not description_files:
    print(f"⚠️  No description files found in {descriptions_dir}")
    print("Expected files like: new_order_description.txt, payment_description.txt, etc.")
    exit(1)

print(f"📋 Found {len(description_files)} transaction descriptions")

for filename in sorted(description_files):
    transaction_name = filename.replace("_description.txt", "")
    description_path = os.path.join(descriptions_dir, filename)

    with open(description_path, "r") as f:
        description_text = f.read()

    print(f"\n{'='*60}")
    print(f"🚀 Generating SQL for: {transaction_name}")
    print(f"{'='*60}")

    try:
        sql_function = generate_sql(schema_text, description_text)
    except Exception as e:
        print(f"❌ Error generating SQL for {transaction_name}: {e}")
        continue

    output_path = os.path.join(outputs_dir, f"{transaction_name}.sql")
    with open(output_path, "w") as f:
        f.write(sql_function)

    print(f"✅ Saved to: {output_path}")
    print(f"\n📝 Preview (first 500 chars):")
    print(f"---\n{sql_function[:500]}...\n---")

print(f"\n{'='*60}")
print(f"✨ All done! Generated {len(description_files)} transaction functions")
print(f"📁 Output directory: {outputs_dir}")
print(f"{'='*60}")