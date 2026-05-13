import os
import subprocess

# 指定输入和输出地址
input_onnx_path = "policy_convert/t800/policy.onnx"
output_mnn_path = "policy_convert/t800/dance1_subject1.mnn"

def convert_onnx_to_mnn(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"Error: Input file {input_path} not found.")
        return

    # 确保输出目录存在
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    print(f"Converting {input_path} to {output_path}...")
    
    # 构造 mnnconvert 命令
    # 使用 --framework ONNX 指定输入格式
    # 使用 --modelFile 指定输入文件
    # 使用 --MNNModel 指定输出文件
    command = [
        "mnnconvert",
        "-f", "ONNX",
        "--modelFile", input_path,
        "--MNNModel", output_path
    ]

    try:
        # 在 yolo 环境下运行（假设当前环境或通过 conda run 调用）
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode == 0:
            print("Conversion successful!")
            print(result.stdout)
        else:
            print("Conversion failed!")
            print(result.stderr)
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    convert_onnx_to_mnn(input_onnx_path, output_mnn_path)
