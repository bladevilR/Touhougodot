"""
优化版绿幕移除工具 - 更精确的抠图
"""
from PIL import Image
import os
from pathlib import Path

def remove_green_screen_v2(input_path, output_path):
    """
    使用更精确的算法移除绿幕背景
    """
    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()
    width, height = img.size

    # 采样背景颜色（从四个角落采样）
    sample_points = [
        (10, 10), (width - 10, 10),
        (10, height - 10), (width - 10, height - 10)
    ]

    bg_colors = []
    for x, y in sample_points:
        r, g, b, a = pixels[x, y]
        bg_colors.append((r, g, b))

    # 计算平均背景颜色
    avg_r = sum(c[0] for c in bg_colors) // len(bg_colors)
    avg_g = sum(c[1] for c in bg_colors) // len(bg_colors)
    avg_b = sum(c[2] for c in bg_colors) // len(bg_colors)

    print(f"检测到的背景颜色: RGB({avg_r}, {avg_g}, {avg_b})")

    # 遍历所有像素
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            # 计算与背景色的欧氏距离
            distance = ((r - avg_r) ** 2 + (g - avg_g) ** 2 + (b - avg_b) ** 2) ** 0.5

            # 如果颜色接近背景色，设为透明
            # 使用更大的阈值来确保边缘也被移除
            if distance < 80:  # 可以调整这个阈值
                pixels[x, y] = (r, g, b, 0)
            # 对于边缘半透明处理
            elif distance < 120:
                # 根据距离计算透明度
                alpha = int((distance - 80) / 40 * 255)
                pixels[x, y] = (r, g, b, alpha)

    img.save(output_path, "PNG")
    print(f"已处理: {os.path.basename(output_path)}")

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
        print(f"\n进度: {i}/{total}")
        remove_green_screen_v2(str(png_file), str(output_file))

    print(f"\n\n全部完成！处理了 {total} 个文件")
    print(f"输出目录: {output_path}")

if __name__ == "__main__":
    input_directory = r"E:\touhou\game\public\punch\1"
    output_directory = r"E:\touhou\game\touhou-godot\assets\sprites\characters\punch"

    batch_process(input_directory, output_directory)
