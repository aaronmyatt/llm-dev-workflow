import os
import sys

import tree_sitter_python as tspython
from tree_sitter import Language, Parser

# Define paths to your repositories
REPO_DIR = os.path.expanduser("~/path/to/tree-sitter-repos")

# Define languages you want to support
LANGUAGES = {
    'python': Language(tspython.language()),
    # 'javascript': f"{REPO_DIR}/tree-sitter-javascript",
    # 'typescript': f"{REPO_DIR}/tree-sitter-typescript/typescript",
    # Add more languages as needed
}

def main():
    try:
        with open('./lib/extract_language_features.py', 'rb') as f:
            s = f.read()
            p = Parser(LANGUAGES.get('python'))
            tree = p.parse(s)
        print(tree)
        import pdb; pdb.set_trace()
    except Exception as e:
        print(f"Error building language library: {e}")
        sys.exit(1)

if __name__ == "__main__":
     main()