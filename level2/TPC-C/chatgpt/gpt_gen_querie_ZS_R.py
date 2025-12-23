import os

# === CONFIG ===
schema_file = "../schema.txt"
descriptions_dir = "../transaction_descriptions"  
outputs_dir = "results_ZS_R/prompts_for_gpt"

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
- Respect the inputs and outputs parameters, respect foreign key constraints, careful with ambiguous references for columns and tables
- Implement proper locking and process operations in a consistent order to prevent deadlocks in high-concurrency environments.

Format: Return the complete CREATE OR REPLACE FUNCTION statement.
Let's think step by step!
"""


# === Read schema ===
with open(schema_file, "r") as f:
    schema_text = f.read()


def generate_prompt(schema, question):
    prompt = f"""DATABASE SCHEMA:
{schema}

QUESTION:
[{question}]

Instructions:
{instruction}
"""
    return prompt


# === Process all descriptions ===
for filename in os.listdir(descriptions_dir):
    if filename.endswith("_description.txt"):
        query_name = filename.replace("_description.txt", "")
        description_path = os.path.join(descriptions_dir, filename)

        with open(description_path, "r") as f:
            description_text = f.read()

        print(f"\n📝 Generating prompt for: {query_name}...")

        prompt = generate_prompt(schema_text, description_text)

        output_path = os.path.join(outputs_dir, f"{query_name}_prompt.txt")
        with open(output_path, "w") as f:
            f.write(prompt)

        print(f"✅ Saved to: {output_path}")

print(f"\n🎉 All prompts generated in folder: {outputs_dir}")
print(f"📋 Copy and paste each prompt into ChatGPT manually.")