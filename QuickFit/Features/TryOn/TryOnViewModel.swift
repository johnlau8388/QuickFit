import SwiftUI
import Combine

@MainActor
class TryOnViewModel: ObservableObject {
    // MARK: - Published 属性
    @Published var clothingImage: UIImage?
    @Published var resultImage: UIImage?

    @Published var showClothingPhotoPicker = false
    @Published var showWardrobePicker = false

    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showSaveSuccess = false
    @Published var showFavoriteSuccess = false
    @Published var showAddToWardrobeAlert = false
    @Published var showAddClothingSheet = false
    @Published var showResultSheet = false

    // 当前选中的衣柜衣物（如果是从衣柜选择的）
    @Published var selectedClothingItem: ClothingItem?

    // 当前穿搭是否已收藏
    @Published var isCurrentOutfitFavorited = false

    private var storage = StorageService.shared
    private var currentOutfitId: UUID?

    // MARK: - 计算属性
    // 从用户资料获取形象照片
    var personImage: UIImage? {
        guard let data = storage.userProfile.fullBodyImageData else { return nil }
        return UIImage(data: data)
    }

    var hasPersonImage: Bool {
        storage.userProfile.hasFullBodyImage
    }

    var canGenerate: Bool {
        hasPersonImage && clothingImage != nil
    }

    // 用户身体描述（用于提升AI效果）
    var bodyDescription: String? {
        storage.userProfile.bodyDescription
    }

    // MARK: - 从衣柜选择衣物
    func selectFromWardrobe(_ item: ClothingItem) {
        selectedClothingItem = item
        clothingImage = UIImage(data: item.imageData)
        showWardrobePicker = false
    }

    // MARK: - 清除服装选择
    func clearClothing() {
        clothingImage = nil
        selectedClothingItem = nil
        resultImage = nil
        isCurrentOutfitFavorited = false
        currentOutfitId = nil
    }

    // MARK: - 生成试衣效果
    func generateTryOn() {
        guard let personImg = personImage else {
            errorMessage = "请先在「我的」页面设置形象照片"
            return
        }

        guard let clothingImg = clothingImage else {
            errorMessage = "请选择要试穿的服装"
            return
        }

        isGenerating = true
        errorMessage = nil
        isCurrentOutfitFavorited = false
        currentOutfitId = nil

        // DEBUG模式：模拟生成效果（用于测试UI）
        #if DEBUG
        simulateGeneration(personImg: personImg, clothingImg: clothingImg)
        #else
        callAPIGeneration(personImg: personImg, clothingImg: clothingImg)
        #endif
    }

    // MARK: - 模拟生成（测试用）
    #if DEBUG
    private func simulateGeneration(personImg: UIImage, clothingImg: UIImage) {
        Task {
            // 模拟网络延迟
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒

            // 创建一个合成的预览图（简单叠加效果）
            let renderer = UIGraphicsImageRenderer(size: personImg.size)
            let compositeImage = renderer.image { context in
                // 绘制人物图
                personImg.draw(in: CGRect(origin: .zero, size: personImg.size))

                // 在中间位置半透明叠加服装图（模拟效果）
                let clothingSize = CGSize(
                    width: personImg.size.width * 0.6,
                    height: personImg.size.width * 0.6
                )
                let clothingOrigin = CGPoint(
                    x: (personImg.size.width - clothingSize.width) / 2,
                    y: personImg.size.height * 0.25
                )
                clothingImg.draw(in: CGRect(origin: clothingOrigin, size: clothingSize), blendMode: .normal, alpha: 0.7)
            }

            resultImage = compositeImage
            isGenerating = false
            showResultSheet = true
        }
    }
    #endif

    // MARK: - 调用API生成
    private func callAPIGeneration(personImg: UIImage, clothingImg: UIImage) {
        Task {
            do {
                // 准备图片数据
                guard let personData = ImageService.shared.prepareImageForUpload(personImg),
                      let clothingData = ImageService.shared.prepareImageForUpload(clothingImg) else {
                    errorMessage = "图片处理失败"
                    isGenerating = false
                    return
                }

                // 调用API
                let response = try await APIService.shared.tryOnClothing(
                    personImageData: personData,
                    clothingImageData: clothingData
                )

                if response.success, let resultBase64 = response.resultImageBase64 {
                    if let resultImg = ImageService.shared.imageFromBase64(resultBase64) {
                        resultImage = resultImg
                        showResultSheet = true
                    } else {
                        errorMessage = "结果图片解析失败"
                    }
                } else {
                    errorMessage = response.message ?? "生成失败，请重试"
                }
            } catch {
                errorMessage = "网络错误: \(error.localizedDescription)"
                print("API调用错误: \(error)")
            }

            isGenerating = false
        }
    }

    // MARK: - 处理收藏
    func handleFavorite() {
        // 如果已经收藏，取消收藏
        if isCurrentOutfitFavorited, let outfitId = currentOutfitId {
            if let outfit = storage.outfitCollections.first(where: { $0.id == outfitId }) {
                storage.removeOutfitCollection(outfit)
                isCurrentOutfitFavorited = false
                currentOutfitId = nil
            }
            return
        }

        // 检查衣物是否在衣柜中
        if selectedClothingItem != nil {
            // 衣物来自衣柜，直接收藏
            saveToFavorites()
        } else {
            // 衣物不在衣柜，提示用户添加
            showAddClothingSheet = true
        }
    }

    // MARK: - 添加衣物到衣柜并收藏
    func addClothingToWardrobeAndFavorite() {
        showAddClothingSheet = true
    }

    // MARK: - 保存衣物并收藏
    func saveClothingAndFavorite(name: String, category: ClothingCategory) {
        guard let clothingImg = clothingImage,
              let item = storage.createClothingItem(from: clothingImg, name: name, category: category) else {
            errorMessage = "添加衣物失败"
            return
        }

        // 添加到衣柜
        storage.addClothingItem(item)
        selectedClothingItem = item

        // 然后收藏
        saveToFavorites()
        showAddClothingSheet = false
    }

    // MARK: - 保存到收藏夹
    private func saveToFavorites() {
        guard let personImg = personImage,
              let resultImg = resultImage,
              let personData = personImg.jpegData(compressionQuality: 0.8),
              let resultData = resultImg.jpegData(compressionQuality: 0.8) else {
            errorMessage = "保存失败"
            return
        }

        var clothingIds: [UUID] = []
        if let item = selectedClothingItem {
            clothingIds.append(item.id)
        }

        let outfit = OutfitCollection(
            personImageData: personData,
            clothingItems: clothingIds,
            resultImageData: resultData
        )

        storage.addOutfitCollection(outfit)
        currentOutfitId = outfit.id
        isCurrentOutfitFavorited = true
        showFavoriteSuccess = true
    }

    // MARK: - 保存到相册
    func saveResultToPhotos() {
        guard let image = resultImage else { return }

        ImageService.shared.saveImageToPhotos(image) { [weak self] success, error in
            if success {
                self?.showSaveSuccess = true
            } else {
                self?.errorMessage = error?.localizedDescription ?? "保存失败"
            }
        }
    }

    // MARK: - 分享
    func shareResult() {
        guard let image = resultImage else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // 获取当前窗口场景
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            // iPad需要设置popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            }
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - 清除结果
    func clearResult() {
        resultImage = nil
        errorMessage = nil
        isCurrentOutfitFavorited = false
        currentOutfitId = nil
    }

    // MARK: - 重置所有
    func reset() {
        clothingImage = nil
        resultImage = nil
        selectedClothingItem = nil
        errorMessage = nil
        isCurrentOutfitFavorited = false
        currentOutfitId = nil
    }
}
