import SwiftUI

struct CollectionView: View {
    @StateObject private var viewModel = CollectionViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.collections.isEmpty {
                    EmptyCollectionView()
                } else {
                    CollectionGridView(
                        collections: viewModel.collections,
                        onDelete: { outfit in
                            viewModel.deleteCollection(outfit)
                        },
                        onTap: { outfit in
                            viewModel.selectedOutfit = outfit
                        }
                    )
                }
            }
            .navigationTitle(L10n.collectionTitle)
            .sheet(item: $viewModel.selectedOutfit) { outfit in
                OutfitDetailView(outfit: outfit) {
                    viewModel.deleteCollection(outfit)
                    viewModel.selectedOutfit = nil
                }
            }
        }
    }
}

// MARK: - 空状态
struct EmptyCollectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L10n.collectionEmpty)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(L10n.collectionEmptyHint)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - 收藏网格
struct CollectionGridView: View {
    let collections: [OutfitCollection]
    let onDelete: (OutfitCollection) -> Void
    let onTap: (OutfitCollection) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(collections) { outfit in
                    OutfitCard(outfit: outfit)
                        .onTapGesture {
                            onTap(outfit)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                onDelete(outfit)
                            } label: {
                                Label(L10n.delete, systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
}

struct OutfitCard: View {
    let outfit: OutfitCollection

    var body: some View {
        VStack(spacing: 8) {
            if let uiImage = UIImage(data: outfit.resultImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .cornerRadius(12)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name.isEmpty ? L10n.collectionOutfitPrefix(String(outfit.id.uuidString.prefix(4))) : outfit.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - 穿搭详情
struct OutfitDetailView: View {
    let outfit: OutfitCollection
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 试衣效果图
                    if let uiImage = UIImage(data: outfit.resultImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 450)
                            .cornerRadius(12)
                    }

                    // 信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text(outfit.name.isEmpty ? L10n.collectionOutfit : outfit.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack {
                            Image(systemName: "calendar")
                            Text(outfit.createdAt.formatted(date: .long, time: .shortened))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        if !outfit.clothingItems.isEmpty {
                            HStack {
                                Image(systemName: "tshirt")
                                Text(L10n.collectionItemsCount(outfit.clothingItems.count))
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // 操作按钮
                    HStack(spacing: 16) {
                        Button {
                            shareOutfit()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text(L10n.share)
                            }
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Button {
                            saveToPhotos()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text(L10n.save)
                            }
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 20)

                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(L10n.collectionUnfavorite)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle(L10n.collectionOutfitDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareOutfit() {
        guard let image = UIImage(data: outfit.resultImageData) else { return }

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

    private func saveToPhotos() {
        guard let image = UIImage(data: outfit.resultImageData) else { return }
        ImageService.shared.saveImageToPhotos(image) { _, _ in }
    }
}

#Preview {
    CollectionView()
}
