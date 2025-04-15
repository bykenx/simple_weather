#!/bin/bash

# 检查是否安装了svg2png
if ! command -v svg2png &> /dev/null; then
    echo "Error: svg2png is not installed. Please install it using:"
    echo "brew install svg2png"
    exit 1
fi

# 检查是否提供了输入文件
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_svg_file>"
    echo "Example: $0 ../assets/app_icon.svg"
    exit 1
fi

# 获取输入文件路径
input_file="$1"

# 检查文件是否存在
if [ ! -f "$input_file" ]; then
    echo "Error: File $input_file does not exist"
    exit 1
fi

# 检查文件扩展名
if [[ ! "$input_file" =~ \.svg$ ]]; then
    echo "Error: Input file must be an SVG file"
    exit 1
fi

# 获取输出文件名（将.svg替换为.png）
output_file="${input_file%.svg}.png"

# 转换SVG到PNG
echo "Converting $input_file to $output_file..."
svg2png "$input_file" --width=1024 --height=1024 "$output_file"

# 检查转换是否成功
if [ $? -eq 0 ]; then
    echo "Conversion successful!"
    echo "Output file: $output_file"
else
    echo "Conversion failed!"
    exit 1
fi 