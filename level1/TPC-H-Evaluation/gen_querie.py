import os
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM


schema_file = "schema.txt"
descriptions_dir = "descriptions"
outputs_dir = "generated_sql"
base_model_name = "Qwen/Qwen2.5-3B-Instruct" 

os.makedirs(outputs_dir, exist_ok=True)


tokenizer = AutoTokenizer.from_pretrained(base_model_name)
model = AutoModelForCausalLM.from_pretrained(
    base_model_name,
    torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
    device_map="auto"
)

if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token


instruction = """
You are a SQL expert.
Using the database schema and the business question provided,
generate a valid PostgreSQL query that answers the question.
Do NOT include explanations or comments.
Return ONLY the SQL code.
"""

# LÊ O SCHEMA
with open(schema_file, "r") as f:
    schema_text = f.read()

def generate_sql(schema, question):
    prompt = f"""<|system|>
{instruction.strip()}
<|user|>
DATABASE SCHEMA:
{schema}

QUESTION:
{question}

"""
    
    print("Prompt: ", prompt)
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

    outputs = model.generate(
        **inputs,
        max_new_tokens=300,
        do_sample=False,
        pad_token_id=tokenizer.eos_token_id,
        eos_token_id=tokenizer.eos_token_id,
    )

    # Extrai apenas a parte gerada
    sql = tokenizer.decode(outputs[0][inputs['input_ids'].shape[1]:], skip_special_tokens=True)
    sql = sql.strip().strip("```").strip("sql").strip()
    return sql

# ==========================
# PROCESSA TODAS AS DESCRIÇÕES
# ==========================
for filename in os.listdir(descriptions_dir):
    if filename.endswith("_description.txt"):
        query_name = filename.replace("_description.txt", "")
        description_path = os.path.join(descriptions_dir, filename)

        with open(description_path, "r") as f:
            description_text = f.read()

        print(f"\n🧠 Gerar SQL para {query_name}...")

        sql_query = generate_sql(schema_text, description_text)

        output_path = os.path.join(outputs_dir, f"{query_name}_ZS.sql")
        with open(output_path, "w") as f:
            f.write(sql_query)

        print(f"✅ SQL guardado em: {output_path}")
        print(f"---\n{sql_query}\n---")
