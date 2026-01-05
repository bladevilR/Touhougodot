"""
智能绿幕移除 - 放宽阈值并使用洪水填充
"""
from PIL import Image
import colorsys
import os
from pathlib import Path

def remove_green_screen_v5(input_path, output_path):
    """
    使用更宽松的HSV范围来移除所有背景
    """
    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()
    width, height = img.size

    processed = 0

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            # 转换到HSV
            h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)

            # 更宽松的青绿色范围，但排除角色常见颜色
            # 背景是冷色调（蓝绿），角色主要是暖色调（红、米色、棕色）和无色（白、灰）
            is_background = (
                0.43 <= h <= 0.60 and  # 青色到青绿色范围
                s >= 0.15 and          # 有一定饱和度（排除灰色）
                0.30 <= v <= 0.55      # 中等明度
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
        count = remove_green_screen_v5(str(png_file), str(output_file))
        print(f"进度: {i}/{total} - {png_file.name} (移除 {count} 像素)")

    print(f"\n全部完成！处理了 {total} 个文件")
    print(f"输出目录: {output_path}")

if __name__ == "__main__":
    input_directory = r"E:\touhou\game\public\punch\1"
    output_directory = r"E:\touhou\game\touhou-godot\assets\sprites\characters\punch"

    batch_process(input_directory, output_directory)
