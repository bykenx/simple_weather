#!/bin/bash

if ! command -v svg2png &> /dev/null; then
    echo "Error: svg2png is not installed. Please install it using:"
    echo "brew install svg2png"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_svg_file>"
    echo "Example: $0 ../assets/app_icon.svg"
    exit 1
fi

input_file="$1"

if [ ! -f "$input_file" ]; then
    echo "Error: File $input_file does not exist"
    exit 1
fi

if [[ ! "$input_file" =~ \.svg$ ]]; then
    echo "Error: Input file must be an SVG file"
    exit 1
fi

output_file="${input_file%.svg}.png"

echo "Converting $input_file to $output_file..."
svg2png "$input_file" --width=1024 --height=1024 "$output_file"

if [ $? -eq 0 ]; then
    echo "Conversion successful!"
    echo "Output file: $output_file"
else
    echo "Conversion failed!"
    exit 1
fi
