"""
优化版绿幕移除工具 - 精确保留角色细节
"""
from PIL import Image
import os
from pathlib import Path

def remove_green_screen_v3(input_path, output_path):
    """
    更保守的算法，只移除纯背景色，保留角色细节
    """
    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()
    width, height = img.size

    # 背景色范围 RGB(70-72, 98-99, 108-109)
    bg_r_range = (68, 74)
    bg_g_range = (96, 101)
    bg_b_range = (106, 111)

    # 遍历所有像素
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            # 严格匹配背景色范围
            is_background = (
                bg_r_range[0] <= r <= bg_r_range[1] and
                bg_g_range[0] <= g <= bg_g_range[1] and
                bg_b_range[0] <= b <= bg_b_range[1]
            )

            if is_background:
                pixels[x, y] = (r, g, b, 0)

    img.save(output_path, "PNG")

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
        print(f"进度: {i}/{total} - {png_file.name}")
        remove_green_screen_v3(str(png_file), str(output_file))

    print(f"\n全部完成！处理了 {total} 个文件")
    print(f"输出目录: {output_path}")

if __name__ == "__main__":
    input_directory = r"E:\touhou\game\public\punch\1"
    output_directory = r"E:\touhou\game\touhou-godot\assets\sprites\characters\punch"

    batch_process(input_directory, output_directory)
