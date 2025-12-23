import os
import google.generativeai as genai
from dotenv import load_dotenv

# === CONFIG ===
schema_file = "../schema.txt"
descriptions_dir = "../queries_descriptions"
outputs_dir = "results_ZS"

# Gemini Model
model_name = "gemini-2.5-pro"

# Load Gemini API key
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "YOUR_API_KEY_HERE")

# Configure Gemini
genai.configure(api_key=GEMINI_API_KEY)

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

Instructions:
{instruction}
"""
    print("🧠 Sending request to Gemini...")
    
    try:
        # Create model with system instruction
        model = genai.GenerativeModel(
            model_name=model_name,
            system_instruction=instruction
        )
        
        # Generate content
        response = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                temperature=0.0,
            )
        )
        
        sql = response.text.strip()
        
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
        raise Exception(f"Gemini API Error: {str(e)}")


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