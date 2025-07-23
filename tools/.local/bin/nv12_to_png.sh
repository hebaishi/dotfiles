#!/bin/bash

# Check if all required parameters are provided
if [ $# -lt 4 ]; then
    echo "Error: Insufficient parameters"
    echo "Usage: $(basename $0) <input_file> <output_file> <width> <height>"
    echo ""
    echo "Parameters:"
    echo "  <input_file>  : Path to the input NV12 raw video file"
    echo "  <output_file> : Path to the output PNG file"
    echo "  <width>       : Width of the input video in pixels"
    echo "  <height>      : Height of the input video in pixels"
    echo ""
    echo "Example: $(basename $0) input.nv12 output.png 1920 1080"
    exit 1
fi

input_file=$1
output_file=$2
width=$3
height=$4

ffmpeg -f rawvideo -s $width"x"$height -pix_fmt nv12 -i $input_file -vframes 1  $output_file
