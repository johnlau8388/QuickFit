import SwiftUI

@MainActor
class CollectionViewModel: ObservableObject {
    @Published var selectedOutfit: OutfitCollection?

    private var storage = StorageService.shared

    var collections: [OutfitCollection] {
        storage.outfitCollections
    }

    func deleteCollection(_ outfit: OutfitCollection) {
        storage.removeOutfitCollection(outfit)
    }

    func updateCollection(_ outfit: OutfitCollection) {
        storage.updateOutfitCollection(outfit)
    }
}
