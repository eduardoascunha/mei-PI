import os
import numpy as np
import pickle
from sentence_transformers import SentenceTransformer


# === CONFIGURATION ===
schema_file = "../schema.txt"
descriptions_dir = "../queries_descriptions"
cot_dir = "../cot_examples"  # Directory with CoT files
outputs_dir = "results_FS5E_COT_04/prompts_for_gpt"

# MMR configuration
NUM_EXAMPLES = 5        # Number of examples to select via MMR
MMR_LAMBDA = 0.4        # Balance: 0.6 = 60% similarity, 40% diversity

# Embeddings cache
CACHE_FILE = "embeddings_cache_cot_gpt.pkl"
EMBEDDING_MODEL = 'BAAI/bge-small-en-v1.5'

os.makedirs(outputs_dir, exist_ok=True)


# === SYSTEM INSTRUCTION ===
SYSTEM_INSTRUCTION = """
You are a SQL expert.
The examples below show reasoning patterns and SQL queries.
Follow the same step-by-step thinking approach for the new question.
Return ONLY the SQL code without markdown formatting or explanations.
"""


def load_schema():
    """Load database schema"""
    with open(schema_file, "r") as f:
        return f.read()


def load_cot_example(query_name):
    """Load CoT file for a given query"""
    cot_path = os.path.join(cot_dir, f"{query_name}_cot.txt")
    
    if not os.path.exists(cot_path):
        return None
    
    with open(cot_path, "r") as f:
        content = f.read().strip()
    
    # Parse CoT file sections
    sections = {}
    current_section = None
    current_content = []
    
    for line in content.split('\n'):
        if line.startswith('QUESTION:'):
            if current_section:
                sections[current_section] = '\n'.join(current_content).strip()
            current_section = 'question'
            current_content = []
        elif line.startswith('CHAIN OF THOUGHT:'):
            if current_section:
                sections[current_section] = '\n'.join(current_content).strip()
            current_section = 'cot'
            current_content = []
        elif line.startswith('SQL QUERY:'):
            if current_section:
                sections[current_section] = '\n'.join(current_content).strip()
            current_section = 'sql'
            current_content = []
        else:
            current_content.append(line)
    
    # Don't forget the last section
    if current_section:
        sections[current_section] = '\n'.join(current_content).strip()
    
    return {
        'description': sections.get('question', ''),
        'cot': sections.get('cot', ''),
        'sql': sections.get('sql', '')
    }


def load_or_build_embeddings_cache(embedder, query_pool):
    """Load cached embeddings or build them if needed"""
    
    if os.path.exists(CACHE_FILE):
        print("📦 Loading cached embeddings...")
        with open(CACHE_FILE, 'rb') as f:
            cache = pickle.load(f)
        
        # Verify cache integrity
        if (cache.get('model') == EMBEDDING_MODEL and 
            cache.get('dimension') == embedder.get_sentence_embedding_dimension()):
            print(f"✅ Cache loaded: {len(cache['embeddings'])} examples\n")
            return cache['embeddings']
        else:
            print("⚠️  Cache outdated, rebuilding...\n")
    
    print("🔨 Building embeddings cache...")
    embeddings = {}
    
    for example_name in query_pool:
        example = load_cot_example(example_name)
        if example:
            emb = embedder.encode(example['description'], convert_to_tensor=False)
            embeddings[example_name] = {
                'embedding': emb,
                'description': example['description'],
                'cot': example['cot'],
                'sql': example['sql']
            }
            print(f"   ✓ {example_name}")
        else:
            print(f"   ✗ {example_name} (not found)")
    
    # Save cache
    cache = {
        'model': EMBEDDING_MODEL,
        'dimension': embedder.get_sentence_embedding_dimension(),
        'embeddings': embeddings
    }
    
    with open(CACHE_FILE, 'wb') as f:
        pickle.dump(cache, f)
    
    print(f"✅ Cache built and saved: {len(embeddings)} examples\n")
    return embeddings


def select_examples_mmr(current_description, embeddings_cache, embedder, current_query_name):
    """
    Select examples using MMR (Maximal Marginal Relevance).
    Balances similarity to query with diversity among selected examples.
    """
    
    # Encode current query
    query_embedding = embedder.encode(current_description, convert_to_tensor=False)
    query_embedding = query_embedding / np.linalg.norm(query_embedding)
    
    # Prepare candidates (exclude current query)
    candidates = []
    candidate_embeddings = []
    
    for query_name, data in embeddings_cache.items():
        if query_name == current_query_name:
            continue
        
        candidates.append({
            'name': query_name,
            'description': data['description'],
            'cot': data['cot'],
            'sql': data['sql']
        })
        
        emb = data['embedding'] / np.linalg.norm(data['embedding'])
        candidate_embeddings.append(emb)
    
    if not candidates:
        return []
    
    candidate_embeddings = np.array(candidate_embeddings)
    
    # Calculate similarities to query
    similarities_to_query = np.dot(candidate_embeddings, query_embedding)
    
    # MMR selection
    selected_indices = []
    remaining_indices = list(range(len(candidates)))
    
    for _ in range(min(NUM_EXAMPLES, len(candidates))):
        if not remaining_indices:
            break
        
        best_idx = None
        best_score = float('-inf')
        
        for idx in remaining_indices:
            # Relevance: similarity to query
            relevance = similarities_to_query[idx]
            
            # Redundancy: max similarity to already selected examples
            if selected_indices:
                selected_embs = candidate_embeddings[selected_indices]
                
                # Ensure selected_embs is always 2D
                if selected_embs.ndim == 1:
                    selected_embs = selected_embs.reshape(1, -1)
                
                # Calculate similarities to all selected examples
                similarities_to_selected = np.dot(
                    candidate_embeddings[idx],
                    selected_embs.T
                )
                
                redundancy = np.max(similarities_to_selected)
            else:
                redundancy = 0
            
            # MMR score: balance relevance and diversity
            mmr_score = MMR_LAMBDA * relevance - (1 - MMR_LAMBDA) * redundancy
            
            if mmr_score > best_score:
                best_score = mmr_score
                best_idx = idx
        
        if best_idx is not None:
            selected_indices.append(best_idx)
            remaining_indices.remove(best_idx)
    
    # Build results with similarity scores (sorted by relevance)
    selected = []
    for idx in selected_indices:
        selected.append({
            'name': candidates[idx]['name'],
            'description': candidates[idx]['description'],
            'cot': candidates[idx]['cot'],
            'sql': candidates[idx]['sql'],
            'similarity': float(similarities_to_query[idx])
        })
    
    # Sort by similarity (most relevant first)
    selected.sort(key=lambda x: x['similarity'], reverse=True)
    
    return selected


def build_few_shot_prompt_with_cot(schema, examples, question):
    """Build the complete few-shot prompt with Chain of Thought for ChatGPT"""
    
    prompt = f"{SYSTEM_INSTRUCTION}\n\n"
    prompt += f"DATABASE SCHEMA:\n{schema}\n\n"
    
    if examples:
        prompt += "Here are some examples of questions with chain-of-thought reasoning and their SQL queries:\n\n"
        
        for i, ex in enumerate(examples, 1):
            prompt += f"--- Example {i} ---\n"
            prompt += f"QUESTION:\n{ex['description']}\n\n"
            prompt += f"CHAIN OF THOUGHT:\n{ex['cot']}\n\n"
            prompt += f"SQL QUERY:\n{ex['sql']}\n\n"
    
    prompt += "--- Your Task ---\n"
    prompt += f"QUESTION:\n{question}\n\n"
    prompt += "Think step by step and then return ONLY the SQL query:\n"
    
    return prompt


# === MAIN EXECUTION ===

def main():
    print("=" * 70)
    print("📝 FEW-SHOT CoT PROMPT GENERATOR FOR CHATGPT (MMR)")
    print("=" * 70)
    
    # Load schema
    print("\n📄 Loading schema...")
    schema = load_schema()
    print("✅ Schema loaded\n")
    
    # Initialize embedder
    print(f"🔄 Loading embedding model ({EMBEDDING_MODEL})...")
    embedder = SentenceTransformer(EMBEDDING_MODEL)
    print("✅ Embedding model loaded\n")
    
    # Get all available queries for the pool (from CoT directory)
    all_queries = set()
    for filename in os.listdir(cot_dir):
        if filename.endswith("_cot.txt"):
            query_name = filename.replace("_cot.txt", "")
            all_queries.add(query_name)
    
    print(f"📋 Total queries in pool: {len(all_queries)}\n")
    
    # Build embeddings cache for all queries
    embeddings_cache = load_or_build_embeddings_cache(embedder, all_queries)
    
    # Configuration summary
    print(f"📊 Configuration:")
    print(f"   - Examples per query: {NUM_EXAMPLES} (selected via MMR)")
    print(f"   - MMR lambda: {MMR_LAMBDA} (higher = more similarity, lower = more diversity)")
    print(f"   - Embedding model: {EMBEDDING_MODEL}")
    print(f"   - CoT directory: {cot_dir}")
    print(f"   - Output directory: {outputs_dir}\n")
    print("=" * 70 + "\n")
    
    # Process all descriptions
    processed = 0
    errors = 0
    
    for filename in sorted(os.listdir(descriptions_dir)):
        if not filename.endswith("_description.txt"):
            continue
        
        query_name = filename.replace("_description.txt", "")
        description_path = os.path.join(descriptions_dir, filename)
        
        with open(description_path, "r") as f:
            description_text = f.read().strip()
        
        print(f"📝 Processing: {query_name}")
        
        # Select examples via MMR
        selected_examples = select_examples_mmr(
            description_text,
            embeddings_cache,
            embedder,
            query_name
        )
        
        if not selected_examples:
            print(f"   ⚠️  No examples available for this query!\n")
            errors += 1
            continue
        
        print(f"   🎯 Selected {len(selected_examples)} examples (sorted by relevance):")
        for ex in selected_examples:
            print(f"      - {ex['name']} (similarity: {ex['similarity']:.3f})")
        
        # Build prompt
        prompt = build_few_shot_prompt_with_cot(schema, selected_examples, description_text)
        
        # Save prompt
        output_path = os.path.join(outputs_dir, f"{query_name}_prompt.txt")
        with open(output_path, "w") as f:
            f.write(prompt)
        
        print(f"   ✅ Saved to: {output_path}")
        
        # Preview
        preview = prompt[:200].replace('\n', ' ')
        if len(prompt) > 200:
            preview += "..."
        print(f"   📋 Preview: {preview}\n")
        
        processed += 1
    
    print("=" * 70)
    print(f"✨ Processing complete!")
    print(f"   - Successful: {processed}")
    print(f"   - Errors: {errors}")
    print(f"\n📋 Copy and paste each prompt from '{outputs_dir}' into ChatGPT manually.")
    print("=" * 70)


if __name__ == "__main__":
    main()