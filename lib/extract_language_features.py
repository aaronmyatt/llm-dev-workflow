import os
import sys
import json
from collections import defaultdict

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

def extract_features(node, features=None, path=None):
    """
    Recursively extract language features from the syntax tree.
    
    Args:
        node: The current tree-sitter node
        features: Dictionary to collect features
        path: Current path in the tree
        
    Returns:
        Dictionary of extracted features
    """
    if features is None:
        features = defaultdict(int)
    if path is None:
        path = []
    
    # Count this node type
    node_type = node.type
    features[node_type] += 1
    
    # Process children
    for child in node.children:
        extract_features(child, features, path + [node_type])
    
    import ipdb; ipdb.set_trace()
    return features

def analyze_file(file_path, language='python'):
    """
    Analyze a file and extract its language features.
    
    Args:
        file_path: Path to the file to analyze
        language: Programming language of the file
        
    Returns:
        Dictionary of extracted features
    """
    try:
        with open(file_path, 'rb') as f:
            source_code = f.read()
        
        parser = Parser()
        parser.set_language(LANGUAGES.get(language))
        tree = parser.parse(source_code)
        
        features = extract_features(tree.root_node)
        import ipdb; ipdb.set_trace()
        return features
    except Exception as e:
        print(f"Error analyzing file {file_path}: {e}")
        return None

def main():
    try:
        # Default to analyzing this file if no arguments provided
        file_path = sys.argv[1] if len(sys.argv) > 1 else './lib/extract_language_features.py'
        
        print(f"Analyzing {file_path}...")
        features = analyze_file(file_path)
        
        if features:
            print(json.dumps(features, indent=2))
            print(f"Found {sum(features.values())} nodes of {len(features)} different types")
        
        import ipdb; ipdb.set_trace()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
     main()
