import os
from PIL import Image
import numpy as np

def remove_background(source_dir, target_dir, target_color_hex):
    # Convert hex to RGB
    target_color_hex = target_color_hex.lstrip('#')
    target_rgb = tuple(int(target_color_hex[i:i+2], 16) for i in (0, 2, 4))
    
    print(f"Target color: {target_rgb}")
    
    # Walk through the source directory
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp')):
                file_path = os.path.join(root, file)
                
                # Determine relative path to maintain structure
                rel_path = os.path.relpath(root, source_dir)
                output_dir = os.path.join(target_dir, rel_path)
                
                if not os.path.exists(output_dir):
                    os.makedirs(output_dir)
                
                output_path = os.path.join(output_dir, file)
                # If the output format doesn't support transparency (like jpg), 
                # we should change extension to png.
                base, ext = os.path.splitext(output_path)
                if ext.lower() != '.png':
                    output_path = base + '.png'
                
                try:
                    img = Image.open(file_path)
                    img = img.convert("RGBA")
                    
                    data = np.array(img)
                    
                    # Create a mask for the target color
                    # Target color is (R, G, B), we check the first 3 channels
                    red, green, blue = data[:,:,0], data[:,:,1], data[:,:,2]
                    mask = (red == target_rgb[0]) & (green == target_rgb[1]) & (blue == target_rgb[2])
                    
                    # Set alpha channel to 0 where mask is True
                    data[:,:,3][mask] = 0
                    
                    # Create new image from data
                    new_img = Image.fromarray(data)
                    new_img.save(output_path)
                    print(f"Processed: {file_path} -> {output_path}")
                    
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    source_directory = r"E:\game\public\punch"
    target_directory = r"E:\game\public\punch_processed"
    hex_color = "47646f"
    
    print(f"Processing images from {source_directory} to {target_directory}...")
    remove_background(source_directory, target_directory, hex_color)
    print("Done.")
