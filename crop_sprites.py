import os
from PIL import Image
import sys

def trim(im):
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

def crop_transparency(im):
    # Get the bounding box of the non-zero regions in the alpha channel
    bbox = im.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

def process_directory(directory):
    print(f"Processing directory: {directory}")
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.png'):
                file_path = os.path.join(root, file)
                try:
                    img = Image.open(file_path)
                    img = img.convert("RGBA")
                    
                    # Crop the image
                    cropped_img = crop_transparency(img)
                    
                    # Check if actually cropped
                    if cropped_img.size != img.size:
                        print(f"Cropping {file}: {img.size} -> {cropped_img.size}")
                        cropped_img.save(file_path)
                    else:
                        print(f"Skipping {file}: Already tight.")
                        
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

def process_file(file_path):
    print(f"Processing file: {file_path}")
    if os.path.exists(file_path):
        try:
            img = Image.open(file_path)
            img = img.convert("RGBA")
            
            # Crop the image
            cropped_img = crop_transparency(img)
            
            # Check if actually cropped
            if cropped_img.size != img.size:
                print(f"Cropping {os.path.basename(file_path)}: {img.size} -> {cropped_img.size}")
                cropped_img.save(file_path)
            else:
                print(f"Skipping {os.path.basename(file_path)}: Already tight.")
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    else:
        print(f"File not found: {file_path}")

if __name__ == "__main__":
    # Directories/Files to process
    target_dirs = [
        r"E:\game\public\punch"
    ]
    
    target_files = [
        r"E:\Touhougodot\assets\stand.png"
    ]
    
    for d in target_dirs:
        if os.path.exists(d):
            process_directory(d)
        else:
            print(f"Directory not found: {d}")
            
    for f in target_files:
        process_file(f)
