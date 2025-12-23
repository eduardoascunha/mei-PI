import os
import glob
import sqlglot
import csv
from collections import Counter
from sqlglot.expressions import Expression
from graphviz import Digraph


# Diretórios onde estão as queries
original_dir = "original/queries"
generated_dir = "generated_sql"
output_csv = "structural_similarity_results.csv"


def parse_query(query_path):
    """Lê e faz parsing da query SQL, retornando a AST."""
    with open(query_path, "r", encoding="utf-8") as f:
        query = f.read().strip()
    try:
        return sqlglot.parse_one(query)
    except Exception:
        return None


def ast_to_graphviz(ast: Expression, filename="ast_example"):
    """Converts a sqlglot AST to a Graphviz image."""
    dot = Digraph(comment="SQL AST")

    def add_node(node, parent_id=None):
        node_id = str(id(node))
        label = type(node).__name__
        dot.node(node_id, label)
        if parent_id:
            dot.edge(parent_id, node_id)
        for child in node.args.values():
            if isinstance(child, Expression):
                add_node(child, node_id)
            elif isinstance(child, list):
                for c in child:
                    if isinstance(c, Expression):
                        add_node(c, node_id)

    add_node(ast)
    dot.render(filename, format="png", cleanup=True)
    print(f"✅ AST image saved as {filename}.png")

def ast_similarity(ast1, ast2):
    """Calcula uma métrica simples de similaridade estrutural."""
    if ast1 is None or ast2 is None:
        return 0.0

    nodes1 = [type(n).__name__ for n in ast1.walk()]
    nodes2 = [type(n).__name__ for n in ast2.walk()]

    c1, c2 = Counter(nodes1), Counter(nodes2)
    all_types = set(c1.keys()) | set(c2.keys())

    intersection = 0
    union = 0

    for t in all_types:
        intersection += min(c1[t], c2[t])
        union += max(c1[t], c2[t])

    score = intersection / union if union else 0
    return round(score, 3)


def compare_queries():
    results = []

    # listar apenas ficheiros SQL originais
    files = sorted(f for f in os.listdir(original_dir) if f.endswith(".sql"))

    for filename in files:
        query_name = os.path.splitext(filename)[0]  # Ex: q1
        orig_path = os.path.join(original_dir, filename)

        # procurar o ficheiro correspondente no diretório gerado (ex: q1_ZS.sql)
        pattern = os.path.join(generated_dir, f"{query_name}_*.sql")
        gen_matches = glob.glob(pattern)

        if not gen_matches:
            print(f"⚠️ Missing generated query for {filename}")
            continue

        gen_path = gen_matches[0]  # assume o primeiro match

        ast_orig = parse_query(orig_path)
        ast_gen = parse_query(gen_path)
        
        
        ast_to_graphviz(ast_orig, filename)

        sim = ast_similarity(ast_orig, ast_gen)
        results.append((filename, os.path.basename(gen_path), sim))
        print(f"{filename} vs {os.path.basename(gen_path)} → Structural similarity = {sim}")

    # calcular média das similaridades
    if results:
        avg_similarity = round(sum(sim for _, _, sim in results) / len(results), 3)
    else:
        avg_similarity = 0.0

    # guardar em CSV
    with open(output_csv, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["Original Query", "Generated Query", "Structural Similarity"])
        writer.writerows(results)
        writer.writerow([])
        writer.writerow(["Average Similarity", "", avg_similarity])

    print(f"\n✅ Results saved to {output_csv}")
    print(f"📊 Average Structural Similarity: {avg_similarity}")


if __name__ == "__main__":
    compare_queries()

