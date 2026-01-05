"""
终极版绿幕移除 - 使用HSV色彩空间精确识别背景
"""
from PIL import Image
import colorsys
import os
from pathlib import Path

def remove_green_screen_v4(input_path, output_path):
    """
    使用HSV色彩空间识别青绿色背景
    """
    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()
    width, height = img.size

    processed = 0

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            # 转换到HSV色彩空间
            h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)

            # 青绿色的色相大约在180度左右（0.5），饱和度中等，明度中等
            # 背景色 RGB(71, 99, 109) 转换后大约是 H=0.48-0.52, S=0.3-0.4, V=0.4-0.45
            is_background = (
                0.45 <= h <= 0.55 and  # 青绿色色相范围
                0.25 <= s <= 0.45 and  # 中等饱和度
                0.35 <= v <= 0.50      # 中等明度
            )

            if is_background:
                pixels[x, y] = (r, g, b, 0)
                processed += 1

    img.save(output_path, "PNG")
    return processed

def batch_process(input_dir, output_dir):
    """批量处理文件夹中的所有PNG图片"""
    input_path = Path(input_dir)
    output_path = Path(output_dir)

    # 创建输出目录
    output_path.mkdir(parents=True, exist_ok=True)

    # 处理所有PNG文件
    png_files = sorted(list(input_path.glob("*.png")))
    total = len(png_files)

    print(f"找到 {total} 个PNG文件，开始处理...\n")

    for i, png_file in enumerate(png_files, 1):
        output_file = output_path / png_file.name
        count = remove_green_screen_v4(str(png_file), str(output_file))
        print(f"进度: {i}/{total} - {png_file.name} (移除 {count} 像素)")

    print(f"\n全部完成！处理了 {total} 个文件")
    print(f"输出目录: {output_path}")

if __name__ == "__main__":
    input_directory = r"E:\touhou\game\public\punch\1"
    output_directory = r"E:\touhou\game\touhou-godot\assets\sprites\characters\punch"

    batch_process(input_directory, output_directory)
