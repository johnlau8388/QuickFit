import SwiftUI
import Combine

@MainActor
class TryOnViewModel: ObservableObject {
    // MARK: - Published 属性
    @Published var selectedClothingItems: [ClothingItem] = []
    @Published var uploadedClothingImages: [UIImage] = []
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

    // 当前穿搭是否已收藏
    @Published var isCurrentOutfitFavorited = false

    private var storage = StorageService.shared
    private var currentOutfitId: UUID?

    static let maxClothingItems = 3

    // MARK: - 计算属性
    var personImage: UIImage? {
        guard let data = storage.userProfile.fullBodyImageData else { return nil }
        return UIImage(data: data)
    }

    var hasPersonImage: Bool {
        storage.userProfile.hasFullBodyImage
    }

    var totalClothingCount: Int {
        selectedClothingItems.count + uploadedClothingImages.count
    }

    var canAddMore: Bool {
        totalClothingCount < Self.maxClothingItems
    }

    var canGenerate: Bool {
        hasPersonImage && totalClothingCount > 0
    }

    var selectedCategories: Set<ClothingCategory> {
        Set(selectedClothingItems.map { $0.category })
    }

    var bodyDescription: String? {
        storage.userProfile.bodyDescription
    }

    // 获取所有服装图片（衣柜选择的 + 上传的）
    var allClothingImages: [UIImage] {
        let wardrobeImages = selectedClothingItems.compactMap { UIImage(data: $0.imageData) }
        return wardrobeImages + uploadedClothingImages
    }

    // MARK: - 多件服装操作

    func addFromWardrobe(_ item: ClothingItem) {
        // 同类别替换
        if let existingIndex = selectedClothingItems.firstIndex(where: { $0.category == item.category }) {
            selectedClothingItems[existingIndex] = item
        } else if canAddMore {
            selectedClothingItems.append(item)
        }
        showWardrobePicker = false
    }

    func addUploadedImage(_ image: UIImage) {
        guard canAddMore else { return }
        uploadedClothingImages.append(image)
    }

    func removeClothingItem(_ item: ClothingItem) {
        selectedClothingItems.removeAll { $0.id == item.id }
        clearResult()
    }

    func removeUploadedImage(at index: Int) {
        guard index < uploadedClothingImages.count else { return }
        uploadedClothingImages.remove(at: index)
        clearResult()
    }

    func clearAllClothing() {
        selectedClothingItems.removeAll()
        uploadedClothingImages.removeAll()
        clearResult()
    }

    // MARK: - 生成试衣效果
    func generateTryOn() {
        guard let personImg = personImage else {
            errorMessage = "请先在「我的」页面设置形象照片"
            return
        }

        let clothingImgs = allClothingImages
        guard !clothingImgs.isEmpty else {
            errorMessage = "请选择要试穿的服装"
            return
        }

        isGenerating = true
        errorMessage = nil
        isCurrentOutfitFavorited = false
        currentOutfitId = nil

        #if DEBUG
        simulateGeneration(personImg: personImg, clothingImgs: clothingImgs)
        #else
        callAPIGeneration(personImg: personImg, clothingImgs: clothingImgs)
        #endif
    }

    // MARK: - 模拟生成（测试用）
    #if DEBUG
    private func simulateGeneration(personImg: UIImage, clothingImgs: [UIImage]) {
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            let renderer = UIGraphicsImageRenderer(size: personImg.size)
            let compositeImage = renderer.image { context in
                personImg.draw(in: CGRect(origin: .zero, size: personImg.size))

                for (index, clothingImg) in clothingImgs.enumerated() {
                    let clothingSize = CGSize(
                        width: personImg.size.width * 0.5,
                        height: personImg.size.width * 0.5
                    )
                    let yOffset = personImg.size.height * 0.2 + CGFloat(index) * personImg.size.height * 0.2
                    let clothingOrigin = CGPoint(
                        x: (personImg.size.width - clothingSize.width) / 2,
                        y: yOffset
                    )
                    clothingImg.draw(in: CGRect(origin: clothingOrigin, size: clothingSize), blendMode: .normal, alpha: 0.6)
                }
            }

            resultImage = compositeImage
            isGenerating = false
            showResultSheet = true
        }
    }
    #endif

    // MARK: - 调用API生成
    private func callAPIGeneration(personImg: UIImage, clothingImgs: [UIImage]) {
        Task {
            do {
                guard let personData = ImageService.shared.prepareImageForUpload(personImg) else {
                    errorMessage = "图片处理失败"
                    isGenerating = false
                    return
                }

                var clothingDataArray: [Data] = []
                for img in clothingImgs {
                    guard let data = ImageService.shared.prepareImageForUpload(img) else {
                        errorMessage = "服装图片处理失败"
                        isGenerating = false
                        return
                    }
                    clothingDataArray.append(data)
                }

                let response = try await APIService.shared.tryOnClothing(
                    personImageData: personData,
                    clothingImagesData: clothingDataArray
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
        if isCurrentOutfitFavorited, let outfitId = currentOutfitId {
            if let outfit = storage.outfitCollections.first(where: { $0.id == outfitId }) {
                storage.removeOutfitCollection(outfit)
                isCurrentOutfitFavorited = false
                currentOutfitId = nil
            }
            return
        }

        if !selectedClothingItems.isEmpty && uploadedClothingImages.isEmpty {
            saveToFavorites()
        } else {
            showAddClothingSheet = true
        }
    }

    // MARK: - 添加衣物到衣柜并收藏
    func addClothingToWardrobeAndFavorite() {
        showAddClothingSheet = true
    }

    // MARK: - 保存衣物并收藏
    func saveClothingAndFavorite(name: String, category: ClothingCategory) {
        // Save any uploaded images to wardrobe first
        for img in uploadedClothingImages {
            if let item = storage.createClothingItem(from: img, name: name, category: category) {
                storage.addClothingItem(item)
                selectedClothingItems.append(item)
            }
        }
        uploadedClothingImages.removeAll()

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

        let clothingIds = selectedClothingItems.map { $0.id }

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

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
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
        selectedClothingItems.removeAll()
        uploadedClothingImages.removeAll()
        resultImage = nil
        errorMessage = nil
        isCurrentOutfitFavorited = false
        currentOutfitId = nil
    }
}
