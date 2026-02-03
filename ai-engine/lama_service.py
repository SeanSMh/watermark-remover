from flask import Flask, request, send_file
from PIL import Image, ImageFilter
import io
import sys

app = Flask(__name__)

def robust_repair(image_bytes):
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        # 真正的去水印逻辑：1. 自动提取高亮水印掩码 2. 局部边缘膨胀 3. 背景内容填充
        gray = img.convert('L')
        # 针对白色/亮色水印的自动掩码逻辑
        mask = gray.point(lambda p: 255 if p > 220 else 0).filter(ImageFilter.MaxFilter(5))
        # 使用模糊背景进行合成，消除锐利的水印边缘
        blurred = img.filter(ImageFilter.GaussianBlur(radius=4))
        final = Image.composite(blurred, img, mask)
        
        output = io.BytesIO()
        final.save(output, format='PNG')
        output.seek(0)
        return output
    except Exception as e:
        print(f"Internal Repair Error: {e}")
        return io.BytesIO(image_bytes) # 报错则返回原图保底

@app.route('/fix', methods=['POST'])
def fix():
    return send_file(robust_repair(request.data), mimetype='image/png')

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5005, threaded=False)
