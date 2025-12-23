import os

# === CONFIG ===
schema_file = "../schema.txt"
descriptions_dir = "../queries_descriptions"
outputs_dir = "results_ZS/prompts_for_gpt"

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


def generate_prompt(schema, question):
    prompt = f"""
DATABASE SCHEMA:
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