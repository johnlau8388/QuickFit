import Foundation
import UIKit

// MARK: - 本地存储服务
class StorageService: ObservableObject {
    static let shared = StorageService()

    // MARK: - Published 属性
    @Published var wardrobeItems: [ClothingItem] = []
    @Published var outfitCollections: [OutfitCollection] = []
    @Published var userProfile: UserProfile = UserProfile()

    // MARK: - 存储路径
    private let fileManager = FileManager.default

    private var wardrobeURL: URL {
        getDocumentsDirectory().appendingPathComponent("wardrobe.json")
    }

    private var collectionsURL: URL {
        getDocumentsDirectory().appendingPathComponent("collections.json")
    }

    private var profileURL: URL {
        getDocumentsDirectory().appendingPathComponent("profile.json")
    }

    private init() {
        loadWardrobe()
        loadCollections()
        loadProfile()
    }

    private func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - 衣柜操作

    func loadWardrobe() {
        guard fileManager.fileExists(atPath: wardrobeURL.path) else {
            wardrobeItems = []
            return
        }

        do {
            let data = try Data(contentsOf: wardrobeURL)
            wardrobeItems = try JSONDecoder().decode([ClothingItem].self, from: data)
        } catch {
            print("加载衣柜失败: \(error)")
            wardrobeItems = []
        }
    }

    func saveWardrobe() {
        do {
            let data = try JSONEncoder().encode(wardrobeItems)
            try data.write(to: wardrobeURL)
        } catch {
            print("保存衣柜失败: \(error)")
        }
    }

    func addClothingItem(_ item: ClothingItem) {
        wardrobeItems.append(item)
        saveWardrobe()
    }

    func removeClothingItem(_ item: ClothingItem) {
        wardrobeItems.removeAll { $0.id == item.id }
        saveWardrobe()
    }

    func updateClothingItem(_ item: ClothingItem) {
        if let index = wardrobeItems.firstIndex(where: { $0.id == item.id }) {
            wardrobeItems[index] = item
            saveWardrobe()
        }
    }

    func getClothingItem(by id: UUID) -> ClothingItem? {
        wardrobeItems.first { $0.id == id }
    }

    func getClothingItems(by category: ClothingCategory) -> [ClothingItem] {
        wardrobeItems.filter { $0.category == category }
    }

    func isClothingInWardrobe(imageData: Data) -> ClothingItem? {
        // 简单比较：检查是否有相同的图片数据
        wardrobeItems.first { $0.imageData == imageData }
    }

    // MARK: - 收藏夹操作

    func loadCollections() {
        guard fileManager.fileExists(atPath: collectionsURL.path) else {
            outfitCollections = []
            return
        }

        do {
            let data = try Data(contentsOf: collectionsURL)
            outfitCollections = try JSONDecoder().decode([OutfitCollection].self, from: data)
        } catch {
            print("加载收藏夹失败: \(error)")
            outfitCollections = []
        }
    }

    func saveCollections() {
        do {
            let data = try JSONEncoder().encode(outfitCollections)
            try data.write(to: collectionsURL)
        } catch {
            print("保存收藏夹失败: \(error)")
        }
    }

    func addOutfitCollection(_ outfit: OutfitCollection) {
        outfitCollections.insert(outfit, at: 0)
        saveCollections()
    }

    func removeOutfitCollection(_ outfit: OutfitCollection) {
        outfitCollections.removeAll { $0.id == outfit.id }
        saveCollections()
    }

    func updateOutfitCollection(_ outfit: OutfitCollection) {
        if let index = outfitCollections.firstIndex(where: { $0.id == outfit.id }) {
            outfitCollections[index] = outfit
            saveCollections()
        }
    }

    // MARK: - 用户资料操作

    func loadProfile() {
        guard fileManager.fileExists(atPath: profileURL.path) else {
            userProfile = UserProfile()
            return
        }

        do {
            let data = try Data(contentsOf: profileURL)
            userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("加载用户资料失败: \(error)")
            userProfile = UserProfile()
        }
    }

    func saveProfile() {
        do {
            let data = try JSONEncoder().encode(userProfile)
            try data.write(to: profileURL)
        } catch {
            print("保存用户资料失败: \(error)")
        }
    }

    func updateProfile(_ profile: UserProfile) {
        userProfile = profile
        saveProfile()
    }

    func setFullBodyImage(_ image: UIImage) {
        userProfile.fullBodyImageData = image.jpegData(compressionQuality: 0.8)
        saveProfile()
    }

    func removeFullBodyImage() {
        userProfile.fullBodyImageData = nil
        saveProfile()
    }

    // MARK: - 辅助方法

    func createClothingItem(from image: UIImage, name: String, category: ClothingCategory) -> ClothingItem? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return ClothingItem(name: name, category: category, imageData: imageData)
    }
}
