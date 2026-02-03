import UIKit
import Photos

class ImageService {
    static let shared = ImageService()

    private init() {}

    // MARK: - 压缩图片
    func compressImage(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        var compression: CGFloat = 1.0
        let maxBytes = maxSizeKB * 1024

        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }

        // 如果图片过大，逐步降低质量
        while imageData.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            }
        }

        return imageData
    }

    // MARK: - 调整图片尺寸
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - 保存图片到相册
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有相册权限"]))
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }

    // MARK: - 从Data创建UIImage
    func imageFromBase64(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: data)
    }

    // MARK: - 准备上传的图片（调整尺寸+压缩）
    func prepareImageForUpload(_ image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        // 1. 调整尺寸
        let resized: UIImage
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            resized = resizeImage(image, targetSize: newSize)
        } else {
            resized = image
        }

        // 2. 压缩
        return compressImage(resized, maxSizeKB: 800)
    }
}
