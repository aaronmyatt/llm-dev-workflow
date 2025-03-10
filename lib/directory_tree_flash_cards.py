from directory_tree import DisplayTree
import sys
from gitwalk import gitwalk as walk
from pathlib import Path
import os

def generate_flashcards(tree_text):
    """Takes a textual tree representation of """
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
        
        # Strip ASCII tree characters (├──, └──, etc.) from the filename e.g. `└── apycards.md`
        file_or_dir_name = original_line.strip()
        if '──' in file_or_dir_name:
            file_or_dir_name = file_or_dir_name.split('──', 1)[1].strip()

        file_or_dir_name = file_or_dir_name.replace('/', '')
        
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

def save_flashcards_to_files(flashcards, output_dir="flashcards"):
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    with open(f"{output_dir}/apycards.md", 'w') as f:
        for card in flashcards:
            f.write('## question\n')
            f.write(card['question'])
            f.write('\n\n')
            f.write('## answer\n')
            f.write(card['answer'])
            f.write('\n\n')
    
    print(f"Generated {len(flashcards)} flashcards in {output_dir}/")

def get_directories_for_path(path: str) -> list[str]:
    """
    Get a list of all directories under the path provided.
    We are using gitwalk to respect the gitignore file if
    there is one found in `path`
    """
    directories = []
    for root, _, _ in walk(path):
        pathObj = Path(root)
        absolutePath = pathObj.absolute()
        directories.append(absolutePath)
    return directories

def generate_flashcards_for_directory(path: str) -> list[str]:
    # Generate the directory tree
    directories = get_directories_for_path(path)

    flashcards = []
    for directory in directories:
        if(str(directory) == os.getcwd()): continue
        tree = DisplayTree(str(directory), stringRep=True)
        flashcard_for_directory = generate_flashcards(tree)
        flashcards.extend(flashcard_for_directory)
    return flashcards

def main():
    # Check if a directory path was provided
    if len(sys.argv) > 1:
        directory_path = sys.argv[1]
    else:
        directory_path = "."  # Default to current directory
    
    flashcards = generate_flashcards_for_directory(directory_path)
    
    # Save the flashcards
    save_flashcards_to_files(flashcards)
    
    print(f"Generated flashcards for the directory structure")

if __name__ == "__main__":
     main()
