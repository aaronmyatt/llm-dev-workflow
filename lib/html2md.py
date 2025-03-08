from markdownify import markdownify as md
from requests import get
import sys

def main(args):
    # Default to analyzing this file if no arguments provided
    
    page = get(args[1])
    text = page.text
    extractedMd = md(text)
    print(extractedMd)


if __name__ == "__main__":
     main(sys.argv)