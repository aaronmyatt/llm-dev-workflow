from directory_tree import DisplayTree

def generate_flashcards(tree_text):
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
    
    print(f"Generated {len(flashcards)} flashcards in {output_dir}/")

def main():
    
    
    import ipdb; ipdb.set_trace()


if __name__ == "__main__":
     main()
