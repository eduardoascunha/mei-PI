import os
import requests
from dotenv import load_dotenv

# === CONFIG ===
schema_file = "../schema.txt"
descriptions_dir = "../queries_descriptions"
outputs_dir = "results_ZS"

# choose the model available on OpenRouter
#model_name = "deepseek/deepseek-v3.1-terminus"
model_name = "deepseek/deepseek-chat-v3.1"
#model_name = "deepseek/deepseek-chat-v3.1:free"

# Load OpenRouter API key
load_dotenv()
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "YOUR_API_KEY_HERE")

os.makedirs(outputs_dir, exist_ok=True)

# === System instruction ===
instruction = """
You are a SQL expert.
Using the database schema and the question provided, generate a valid PostgreSQL query that answers the question.
Return ONLY the SQL code without any markdown formatting or explanations.
"""

# === Read schema ===
with open(schema_file, "r") as f:
    schema_text = f.read()


def generate_sql(schema, question):
    prompt = f"""
DATABASE SCHEMA:
{schema}

QUESTION:
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
for filename in os.listdir(descriptions_dir):
    if filename.endswith("_description.txt"):
        query_name = filename.replace("_description.txt", "")
        description_path = os.path.join(descriptions_dir, filename)

        with open(description_path, "r") as f:
            description_text = f.read()

        print(f"\n🚀 Generating SQL for: {query_name}...")

        try:
            sql_query = generate_sql(schema_text, description_text)
        except Exception as e:
            print(f"❌ Error generating SQL for {query_name}: {e}")
            continue

        output_path = os.path.join(outputs_dir, f"{query_name}.sql")
        with open(output_path, "w") as f:
            f.write(sql_query)

        print(f"✅ Saved to: {output_path}")
        print(f"---\n{sql_query}\n---")