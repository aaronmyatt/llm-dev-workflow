from directory_tree import DisplayTree
import sys

def generate_flashcards_by_level(tree_text):
    """
    Generate flashcards organized by directory level to reduce noise and focus on smaller contexts.
    Each flashcard will only show nodes at the same directory level within the same parent.
    """
    # Split the tree into lines
    lines = tree_text.strip().split('\n')
    flashcards = []
    
    # Group lines by their parent directory (based on indentation)
    level_groups = {}
    
    for i, line in enumerate(lines):
        if not line.strip():
            continue
            
        # Calculate indentation level
        indent = len(line) - len(line.lstrip())
        
        # Find parent line (the line above with less indentation)
        parent_indent = -1
        parent_index = -1
        
        for j in range(i-1, -1, -1):
            if not lines[j].strip():
                continue
                
            current_indent = len(lines[j]) - len(lines[j].lstrip())
            if current_indent < indent:
                parent_indent = current_indent
                parent_index = j
                break
        
        # Create a key based on parent index and indent level
        group_key = f"{parent_index}:{indent}"
        
        if group_key not in level_groups:
            level_groups[group_key] = []
        
        level_groups[group_key].append(i)
    
    # Create flashcards for each group
    for group_key, indices in level_groups.items():
        # Skip groups with only one item (not interesting for flashcards)
        if len(indices) <= 1:
            continue
            
        # For each item in the group, create a flashcard
        for target_idx in indices:
            # Create a copy of the lines for this context
            context_lines = []
            
            # Get parent line if it exists
            parent_idx = int(group_key.split(':')[0])
            if parent_idx >= 0:
                context_lines.append(lines[parent_idx])
            
            # Add all siblings (including the target line)
            for idx in indices:
                if idx == target_idx:
                    # For the target line, replace with blank
                    original_line = lines[idx]
                    indent = len(original_line) - len(original_line.lstrip())
                    spaces = ' ' * indent
                    placeholder = spaces + "________"
                    context_lines.append(placeholder)
                else:
                    context_lines.append(lines[idx])
            
            # Create the flashcard
            question_tree = '\n'.join(context_lines)
            answer = lines[target_idx].strip()
            
            flashcard = {
                "question": question_tree,
                "answer": answer,
                "context": f"Level {len(group_key.split(':')[1])}"
            }
            
            flashcards.append(flashcard)
    
    return flashcards

def generate_flashcards(tree_text):
    """Legacy function that creates flashcards for the entire tree at once"""
    # Split the tree into lines
    lines = tree_text.strip().split('\n')
    flashcards = []
    
    # For each line, create a flashcard by hiding that line
    for i in range(len(lines)):
        # Skip empty lines
        if not lines[i].strip():
            continue
            
        # Create a copy of the lines
        question_lines = lines.copy()
        
        # Extract the original line (answer)
        original_line = lines[i]
        
        # Find the indentation level
        indent = len(original_line) - len(original_line.lstrip())
        file_or_dir_name = original_line.strip()
        
        # Replace the line with a blank of the same length, preserving indentation
        spaces = ' ' * indent
        placeholder = spaces + "________" # or any placeholder you prefer
        
        question_lines[i] = placeholder
        
        # Join the lines back into a tree
        question_tree = '\n'.join(question_lines)
        
        # Create the flashcard
        flashcard = {
            "question": question_tree,
            "answer": file_or_dir_name
        }
        
        flashcards.append(flashcard)
    
    return flashcards

# Example usage
def save_flashcards_to_files(flashcards, output_dir="flashcards"):
    import os
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Save each flashcard to a separate file
    for i, card in enumerate(flashcards):
        with open(f"{output_dir}/card_{i+1}_question.txt", "w") as f:
            f.write(card["question"])
        
        with open(f"{output_dir}/card_{i+1}_answer.txt", "w") as f:
            f.write(card["answer"])
        
        # Save context if available
        if "context" in card:
            with open(f"{output_dir}/card_{i+1}_context.txt", "w") as f:
                f.write(card["context"])
    
    print(f"Generated {len(flashcards)} flashcards in {output_dir}/")

def parseDirectoriesFromTree(tree):
    """Extracts directories from an onlyDirs invocation of DisplayTree and verifies they exist"""
    import os
    
    # Get the string representation of the tree
    tree_str = str(tree)
    
    # Split the tree into lines
    lines = tree_str.strip().split('\n')
    
    # Extract directory paths
    directories = []
    base_path = ""
    
    for line in lines:
        if not line.strip():
            continue
        
        # Calculate indentation level
        indent = len(line) - len(line.lstrip())
        dir_name = line.strip()
        
        # If this is the root directory (no indentation)
        if indent == 0:
            base_path = dir_name
            directories.append(base_path)
        else:
            # Find the parent directory based on indentation
            parent_path = None
            parent_indent = -1
            
            # Go through the directories we've already processed
            for i, (path, level) in enumerate([(d, len(d.split('/')) - 1) for d in directories]):
                # If this directory is at the previous indentation level
                if level == indent - 1:
                    parent_path = path
                    parent_indent = level
            
            if parent_path:
                # Construct the full path
                full_path = os.path.join(parent_path, dir_name)
                directories.append(full_path)
    
    # Verify directories exist
    verified_dirs = []
    for directory in directories:
        if os.path.isdir(directory):
            verified_dirs.append(directory)
        else:
            print(f"Warning: Directory '{directory}' does not exist")
    
    return verified_dirs


def main():
    # Check if a directory path was provided
    if len(sys.argv) > 1:
        directory_path = sys.argv[1]
    else:
        directory_path = "."  # Default to current directory
    
    # Generate the directory tree
    directoryTree = DisplayTree(directory_path, stringRep=True, onlyDirs=True)
    directories = parseDirectoriesFromTree(directoryTree)
    
    # Generate a full tree for flashcards
    fullTree = DisplayTree(directory_path)
    tree_text = str(fullTree)
    
    # Generate flashcards by level (new method)
    flashcards = generate_flashcards_by_level(tree_text)
    
    # Save the flashcards
    save_flashcards_to_files(flashcards)
    
    print(f"Processed {len(directories)} directories")


if __name__ == "__main__":
     main()
