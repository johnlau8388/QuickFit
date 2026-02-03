import SwiftUI

@MainActor
class WardrobeViewModel: ObservableObject {
    @Published var showAddSheet = false
    @Published var selectedItem: ClothingItem?

    private var storage = StorageService.shared

    var allItems: [ClothingItem] {
        storage.wardrobeItems
    }

    func getItems(for category: ClothingCategory) -> [ClothingItem] {
        storage.getClothingItems(by: category)
    }

    func addItem(image: UIImage, name: String, category: ClothingCategory) {
        guard let item = storage.createClothingItem(from: image, name: name, category: category) else {
            return
        }
        storage.addClothingItem(item)
    }

    func deleteItem(_ item: ClothingItem) {
        storage.removeClothingItem(item)
    }

    func updateItem(_ item: ClothingItem) {
        storage.updateClothingItem(item)
    }
}
