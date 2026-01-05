"""
批量处理图片，移除绿幕背景
"""
from PIL import Image
import os
from pathlib import Path

def remove_green_screen(input_path, output_path, color_threshold=50):
    """
    移除图片中的暗绿色背景

    Args:
        input_path: 输入图片路径
        output_path: 输出图片路径
        color_threshold: 颜色容差阈值
    """
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    for item in datas:
        # 检测暗青绿色背景 (大约是 #5a7a7c 左右的颜色)
        # R通道较低，G和B通道较高且接近
        r, g, b, a = item

        # 如果是绿幕颜色（青绿色），将alpha设为0
        if abs(g - b) < color_threshold and g > r + 20 and b > r + 20:
            new_data.append((r, g, b, 0))
        else:
            new_data.append(item)

    img.putdata(new_data)
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

    print(f"找到 {total} 个PNG文件，开始处理...")

    for i, png_file in enumerate(png_files, 1):
        output_file = output_path / png_file.name
        remove_green_screen(str(png_file), str(output_file))
        print(f"进度: {i}/{total}")

    print(f"\n全部完成！处理了 {total} 个文件")
    print(f"输出目录: {output_path}")

if __name__ == "__main__":
    input_directory = r"E:\touhou\game\public\punch\1"
    output_directory = r"E:\touhou\game\touhou-godot\assets\sprites\characters\punch"

    batch_process(input_directory, output_directory)
