#!/usr/bin/env python3
"""
Remove background color (#47646f) from sprite images
"""

import os
from PIL import Image
from pathlib import Path

def remove_background(image_path, bg_color=(0x47, 0x64, 0x6f), tolerance=10):
    """
    Remove background color from an image and make it transparent

    Args:
        image_path: Path to the image file
        bg_color: RGB tuple of background color to remove
        tolerance: Color tolerance for matching (0-255)
    """
    try:
        # Open image
        img = Image.open(image_path)

        # Convert to RGBA if not already
        img = img.convert('RGBA')

        # Get image data
        data = img.getdata()

        new_data = []
        for item in data:
            # Check if pixel color is close to background color
            r, g, b = item[0], item[1], item[2]
            if (abs(r - bg_color[0]) <= tolerance and
                abs(g - bg_color[1]) <= tolerance and
                abs(b - bg_color[2]) <= tolerance):
                # Make transparent
                new_data.append((r, g, b, 0))
            else:
                # Keep original
                new_data.append(item)

        # Update image data
        img.putdata(new_data)

        # Save back to original file
        img.save(image_path, 'PNG')
        print(f"Processed: {image_path}")
        return True

    except Exception as e:
        print(f"Error processing {image_path}: {e}")
        return False

def process_directory(base_dir):
    """
    Process all PNG files in directory and subdirectories
    """
    base_path = Path(base_dir)

    # Find all PNG files
    png_files = list(base_path.rglob('*.png'))

    print(f"Found {len(png_files)} PNG files to process")

    success_count = 0
    for png_file in png_files:
        if remove_background(str(png_file)):
            success_count += 1

    print(f"\nCompleted: {success_count}/{len(png_files)} files processed successfully")

if __name__ == '__main__':
    # Process the punch directory
    punch_dir = r'E:\game\public\punch'

    if os.path.exists(punch_dir):
        print(f"Processing sprites in: {punch_dir}")
        print(f"Background color to remove: #47646f")
        print("-" * 50)
        process_directory(punch_dir)
    else:
        print(f"Error: Directory not found: {punch_dir}")
