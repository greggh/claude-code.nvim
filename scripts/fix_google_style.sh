#!/bin/bash

# Fix Google style guide violations in markdown files

echo "Fixing Google style guide violations..."

# Function to convert to sentence case
sentence_case() {
    echo "$1" | sed -E 's/^(#+\s+)(.)/\1\u\2/; s/^(#+\s+\w+)\s+/\1 /; s/\s+([A-Z])/\s+\l\1/g; s/([.!?]\s+)([a-z])/\1\u\2/g'
}

# Fix headings to use sentence-case capitalization
fix_headings() {
    local file="$1"
    echo "Processing $file..."
    
    # Create temp file
    temp_file=$(mktemp)
    
    # Process the file line by line
    while IFS= read -r line; do
        if [[ "$line" =~ ^#+[[:space:]] ]]; then
            # Extract heading level and content
            heading_level=$(echo "$line" | grep -o '^#+')
            content="${line##+}"
            content="${content#" "}"
            
            # Special cases that should remain capitalized
            if [[ "$content" =~ ^(API|CLI|MCP|LSP|IDE|PR|URL|README|CHANGELOG|TODO|FAQ|Q&A) ]] || \
               [[ "$content" == "Ubuntu/Debian" ]] || \
               [[ "$content" == "NEW!" ]] || \
               [[ "$content" =~ ^v[0-9] ]]; then
                echo "$line" >> "$temp_file"
            else
                # Convert to sentence case
                # First word capitalized, rest lowercase unless after punctuation
                new_content=$(echo "$content" | sed -E '
                    s/^(.)/\U\1/;                    # Capitalize first letter
                    s/([[:space:]])([A-Z])/\1\L\2/g; # Lowercase other capitals
                    s/([.!?][[:space:]]+)(.)/\1\U\2/g; # Capitalize after sentence end
                    s/\s*✨$/ ✨/;                   # Preserve emoji placement
                    s/\s*🚀$/ 🚀/;
                ')
                echo "$heading_level $new_content" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$file"
    
    # Replace original file
    mv "$temp_file" "$file"
}

# Fix all markdown files
for file in *.md docs/*.md doc/*.md .github/**/*.md; do
    if [[ -f "$file" ]]; then
        fix_headings "$file"
    fi
done

echo "Heading fixes complete!"

# Fix other Google style violations
echo "Fixing other style violations..."

# Fix word list issues (CLI -> command-line tool, etc.)
find . -name "*.md" -type f ! -path "./.git/*" ! -path "./node_modules/*" ! -path "./.vale/*" -exec sed -i '' \
    -e 's/\bCLI\b/command-line tool/g' \
    -e 's/\bterminate\b/stop/g' \
    -e 's/\bterminated\b/stopped/g' \
    -e 's/\bterminating\b/stopping/g' \
    {} \;

echo "Style fixes complete!"