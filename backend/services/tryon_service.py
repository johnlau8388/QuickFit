import base64


def validate_clothing_images(clothing_images_b64: list[str]) -> list[bytes]:
    """
    验证并解码服装图片列表
    - 最多3张
    - 每张必须是有效的base64编码
    """
    if not clothing_images_b64:
        raise ValueError("至少需要1件服装图片")

    if len(clothing_images_b64) > 3:
        raise ValueError("最多支持3件服装同时试穿")

    decoded = []
    for i, img_b64 in enumerate(clothing_images_b64):
        try:
            data = base64.b64decode(img_b64)
            if len(data) < 100:
                raise ValueError(f"第{i+1}张服装图片数据无效")
            decoded.append(data)
        except Exception as e:
            raise ValueError(f"第{i+1}张服装图片解码失败: {str(e)}")

    return decoded
