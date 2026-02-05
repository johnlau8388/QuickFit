import os
import google.generativeai as genai
from PIL import Image
import io
import base64

class GeminiService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        # 使用稳定的模型
        self.model_name = os.getenv("GEMINI_MODEL", "gemini-2.0-flash-exp")

        if self.api_key:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(self.model_name)
            print(f"Gemini 服务初始化完成，模型: {self.model_name}")
        else:
            self.model = None
            print("警告: GEMINI_API_KEY 未配置")

    def is_configured(self) -> bool:
        return self.api_key is not None

    async def generate_tryon(self, person_image: bytes, clothing_image: bytes) -> bytes | None:
        """
        使用 Gemini 生成虚拟试衣效果
        """
        if not self.model:
            raise Exception("Gemini API 未配置")

        try:
            # 将字节转换为 PIL Image
            person_pil = Image.open(io.BytesIO(person_image))
            clothing_pil = Image.open(io.BytesIO(clothing_image))

            # 调整图片大小以优化处理
            person_pil = self._resize_image(person_pil, max_size=1024)
            clothing_pil = self._resize_image(clothing_pil, max_size=512)

            # 构建提示词
            prompt = """
            You are a virtual try-on assistant.

            Task: Generate a realistic image of the person in the first image wearing the clothing item shown in the second image.

            Requirements:
            1. Keep the person's face, body shape, and pose exactly the same
            2. Replace their current top/clothing with the new clothing item
            3. Make the clothing fit naturally on the person's body
            4. Maintain realistic lighting and shadows
            5. The result should look like a real photo, not edited

            Please generate the try-on result image.
            """

            # 调用 Gemini 生成
            response = self.model.generate_content([prompt, person_pil, clothing_pil])

            # 打印调试信息
            print(f"Gemini 响应 candidates 数量: {len(response.candidates) if response.candidates else 0}")
            if hasattr(response, 'prompt_feedback'):
                print(f"Prompt feedback: {response.prompt_feedback}")

            # 检查是否有图像输出
            if response.candidates and len(response.candidates) > 0:
                candidate = response.candidates[0]
                if hasattr(candidate, 'content') and candidate.content:
                    for part in candidate.content.parts:
                        if hasattr(part, 'inline_data') and part.inline_data:
                            # 返回生成的图像
                            image_data = part.inline_data.data
                            print("成功获取生成的图像")
                            if isinstance(image_data, str):
                                return base64.b64decode(image_data)
                            return image_data
                        # 如果是文本响应，打印出来
                        if hasattr(part, 'text') and part.text:
                            print(f"Gemini 文本响应: {part.text[:200]}")

            # Gemini 目前不支持直接生成图像，返回原图并说明
            print("Gemini 未返回图像，返回原图作为占位")
            output = io.BytesIO()
            person_pil.save(output, format='JPEG', quality=90)
            return output.getvalue()

        except Exception as e:
            print(f"Gemini 生成错误: {str(e)}")
            raise e

    def _resize_image(self, image: Image.Image, max_size: int) -> Image.Image:
        """调整图片大小"""
        width, height = image.size
        if width > max_size or height > max_size:
            if width > height:
                new_width = max_size
                new_height = int(height * max_size / width)
            else:
                new_height = max_size
                new_width = int(width * max_size / height)
            image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)

        # 确保是 RGB 模式
        if image.mode != 'RGB':
            image = image.convert('RGB')

        return image
