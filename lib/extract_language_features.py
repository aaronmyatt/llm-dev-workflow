import os
import sys
import json
from collections import defaultdict

import tree_sitter_python as tspython
from tree_sitter import Language, Parser

# Define languages you want to support
LANGUAGES = {
    'python': Language(tspython.language()),
    # 'javascript': f"{REPO_DIR}/tree-sitter-javascript",
    # 'typescript': f"{REPO_DIR}/tree-sitter-typescript/typescript",
    # Add more languages as needed
}

def walk_tree(node, language):
    """Recursively walk the syntax tree and extract features."""
    features = {
        'functions': [],
        'classes': [],
        'variables': [],
        'imports': []
    }

    # Process current node based on its type
    node_type = node.type

    # Python-specific node processing
    if language == 'python':
        if node_type == 'function_definition':
            # Find the identifier child node which is the function name
            for child in node.children:
                if child.type == 'identifier':
                    features['functions'].append(child.text.decode('utf8'))
                    break

        elif node_type == 'class_definition':
            # Find the identifier child node which is the class name
            for child in node.children:
                if child.type == 'identifier':
                    features['classes'].append(child.text.decode('utf8'))
                    break

        elif node_type == 'import_statement' or node_type == 'import_from_statement':
            for child in node.children:
                # import pdb; pdb.set_trace()
                if child.type == 'dotted_name':
                    features['imports'].append(child.text.decode('utf8').strip())
                    break

    # JavaScript-specific node processing
    elif language == 'javascript':
        if node_type == 'function_declaration':
            # Find the identifier child node which is the function name
            for child in node.children:
                if child.type == 'identifier':
                    features['functions'].append(child.text.decode('utf8'))
                    break

        elif node_type == 'class_declaration':
            # Find the identifier child node which is the class name
            for child in node.children:
                if child.type == 'identifier':
                    features['classes'].append(child.text.decode('utf8'))
                    break

    # Add more language-specific processing as needed

    # Recursively process child nodes and merge their features
    for child in node.children:
        child_features = walk_tree(child, language)
        for feature_type, items in child_features.items():
            features[feature_type].extend(items)

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
    tree = ast_tree_for_file(file_path, language)
    
    features = walk_tree(tree.root_node, language)
    # import ipdb; ipdb.set_trace()
    return features


def ast_tree_for_file(file_path, language):
    with open(file_path, 'rb') as f:
        source_code = f.read()
        
    parser = Parser(LANGUAGES.get(language))
    tree = parser.parse(source_code)
    return tree

def main():
    # Default to analyzing this file if no arguments provided
    file_path = sys.argv[1] if len(sys.argv) > 1 else './lib/extract_language_features.py'
    
    print(f"Analyzing {file_path}...")
    features = analyze_file(file_path)
    
    if features:
        print(json.dumps(features, indent=2))
    
    import ipdb; ipdb.set_trace()


if __name__ == "__main__":
     main()
