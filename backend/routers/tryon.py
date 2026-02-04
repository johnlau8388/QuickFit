from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import base64
from services.gemini_service import GeminiService

router = APIRouter()
gemini_service = GeminiService()

class TryOnRequest(BaseModel):
    person_image: str
    clothing_image: str

class TryOnResponse(BaseModel):
    success: bool
    result_image: str | None = None
    message: str | None = None

@router.post("/generate", response_model=TryOnResponse)
async def generate_tryon(request: TryOnRequest):
    """
    AI虚拟试衣接口
    接收人物照片和服装照片，返回试衣效果图
    """
    try:
        # 解码图片
        person_image_data = base64.b64decode(request.person_image)
        clothing_image_data = base64.b64decode(request.clothing_image)

        # 调用 Gemini 生成试衣效果
        result_image_data = await gemini_service.generate_tryon(person_image_data, clothing_image_data)

        if result_image_data:
            # 编码结果图片
            result_base64 = base64.b64encode(result_image_data).decode('utf-8')
            return TryOnResponse(
                success=True,
                result_image=result_base64,
                message="试衣成功"
            )
        else:
            return TryOnResponse(
                success=False,
                message="AI生成失败，请重试"
            )

    except Exception as e:
        print(f"试衣生成错误: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/status")
async def get_status():
    """检查试衣服务状态"""
    return {
        "service": "tryon",
        "status": "running",
        "gemini_configured": gemini_service.is_configured()
    }
