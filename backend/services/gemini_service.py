import os
import base64
import io
from PIL import Image

# 使用新版 google-genai SDK
from google import genai
from google.genai import types

class GeminiService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        self.model_name = os.getenv("GEMINI_MODEL", "gemini-2.0-flash-exp-image-generation")

        if self.api_key:
            self.client = genai.Client(api_key=self.api_key)
            print(f"Gemini 服务初始化完成，模型: {self.model_name}")
        else:
            self.client = None
            print("警告: GEMINI_API_KEY 未配置")

    def is_configured(self) -> bool:
        return self.api_key is not None

    async def generate_tryon(self, person_image: bytes, clothing_image: bytes) -> bytes | None:
        """
        使用 Gemini 2.0 生成虚拟试衣效果
        """
        if not self.client:
            raise Exception("Gemini API 未配置")

        try:
            # 将字节转换为 PIL Image
            person_pil = Image.open(io.BytesIO(person_image))
            clothing_pil = Image.open(io.BytesIO(clothing_image))

            # 调整图片大小
            person_pil = self._resize_image(person_pil, max_size=1024)
            clothing_pil = self._resize_image(clothing_pil, max_size=512)

            # 转换为 base64
            person_b64 = self._image_to_base64(person_pil)
            clothing_b64 = self._image_to_base64(clothing_pil)

            # 构建提示词
            prompt = """You are an expert virtual try-on AI.

Task: Generate a photorealistic image showing the person from the first image wearing the clothing item from the second image.

Requirements:
1. Keep the person's face, body shape, pose, and background exactly the same
2. Naturally fit the clothing item onto the person's body
3. Adjust clothing wrinkles and shadows to match the person's pose
4. Maintain realistic lighting consistent with the original photo
5. The result should look like an actual photograph, not a digital edit

Generate the virtual try-on result image now."""

            # 调用 Gemini API 生成图像
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=[
                    types.Content(
                        role="user",
                        parts=[
                            types.Part.from_text(prompt),
                            types.Part.from_bytes(
                                data=base64.b64decode(person_b64),
                                mime_type="image/jpeg"
                            ),
                            types.Part.from_bytes(
                                data=base64.b64decode(clothing_b64),
                                mime_type="image/jpeg"
                            ),
                        ]
                    )
                ],
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE", "TEXT"]
                )
            )

            # 检查响应中的图像
            if response.candidates:
                for candidate in response.candidates:
                    if candidate.content and candidate.content.parts:
                        for part in candidate.content.parts:
                            if part.inline_data and part.inline_data.data:
                                print("成功获取生成的图像")
                                return part.inline_data.data
                            if part.text:
                                print(f"Gemini 文本响应: {part.text[:200]}")

            # 返回原图作为 fallback
            print("Gemini 未返回图像，返回原图作为占位")
            return self._pil_to_bytes(person_pil)

        except Exception as e:
            print(f"Gemini 生成错误: {str(e)}")
            # 返回原图而不是抛出错误
            try:
                person_pil = Image.open(io.BytesIO(person_image))
                person_pil = self._resize_image(person_pil, max_size=1024)
                return self._pil_to_bytes(person_pil)
            except:
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

    def _image_to_base64(self, image: Image.Image) -> str:
        """将 PIL Image 转换为 base64"""
        buffer = io.BytesIO()
        image.save(buffer, format='JPEG', quality=90)
        return base64.b64encode(buffer.getvalue()).decode('utf-8')

    def _pil_to_bytes(self, image: Image.Image) -> bytes:
        """将 PIL Image 转换为 bytes"""
        buffer = io.BytesIO()
        image.save(buffer, format='JPEG', quality=90)
        return buffer.getvalue()
