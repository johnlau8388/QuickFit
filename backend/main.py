from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# 加载环境变量
load_dotenv()

# 创建 FastAPI 应用
app = FastAPI(
    title="QuickFit API",
    description="AI虚拟试衣后端服务",
    version="1.0.0"
)

# 配置 CORS（允许 iOS App 访问）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 导入路由
from routers import tryon

# 注册路由
app.include_router(tryon.router, prefix="/api/tryon", tags=["试衣"])

@app.get("/")
async def root():
    return {"message": "QuickFit API 服务运行中"}

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
