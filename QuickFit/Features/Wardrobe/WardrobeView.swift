import SwiftUI
import PhotosUI

struct WardrobeView: View {
    @StateObject private var viewModel = WardrobeViewModel()
    @State private var selectedCategory: ClothingCategory = .tops

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分类标签栏
                CategoryTabBar(selectedCategory: $selectedCategory)

                // 衣物网格
                if viewModel.getItems(for: selectedCategory).isEmpty {
                    EmptyWardrobeView(category: selectedCategory) {
                        viewModel.showAddSheet = true
                    }
                } else {
                    ClothingGridView(
                        items: viewModel.getItems(for: selectedCategory),
                        onDelete: { item in
                            viewModel.deleteItem(item)
                        },
                        onTap: { item in
                            viewModel.selectedItem = item
                        }
                    )
                }
            }
            .navigationTitle(L10n.wardrobeTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                AddClothingSheet(viewModel: viewModel, defaultCategory: selectedCategory)
            }
            .sheet(item: $viewModel.selectedItem) { item in
                ClothingDetailView(item: item, onDelete: {
                    viewModel.deleteItem(item)
                    viewModel.selectedItem = nil
                })
            }
        }
    }
}

// MARK: - 分类标签栏
struct CategoryTabBar: View {
    @Binding var selectedCategory: ClothingCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClothingCategory.allCases) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

struct CategoryTab: View {
    let category: ClothingCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.purple : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - 空状态视图
struct EmptyWardrobeView: View {
    let category: ClothingCategory
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: category.icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L10n.wardrobeEmpty(category.displayName))
                .font(.headline)
                .foregroundColor(.secondary)

            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus")
                    Text(L10n.wardrobeAdd(category.displayName))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.purple)
                .cornerRadius(20)
            }

            Spacer()
        }
    }
}

// MARK: - 衣物网格
struct ClothingGridView: View {
    let items: [ClothingItem]
    let onDelete: (ClothingItem) -> Void
    let onTap: (ClothingItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    ClothingItemCard(item: item)
                        .onTapGesture {
                            onTap(item)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                onDelete(item)
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

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 8) {
            if let uiImage = UIImage(data: item.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            }

            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 添加衣物表单
struct AddClothingSheet: View {
    @ObservedObject var viewModel: WardrobeViewModel
    let defaultCategory: ClothingCategory
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var clothingName = ""
    @State private var selectedCategory: ClothingCategory
    @State private var showPhotoPicker = false

    init(viewModel: WardrobeViewModel, defaultCategory: ClothingCategory) {
        self.viewModel = viewModel
        self.defaultCategory = defaultCategory
        _selectedCategory = State(initialValue: defaultCategory)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(L10n.wardrobePhoto) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                showPhotoPicker = true
                            }
                    } else {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.largeTitle)
                                Text(L10n.wardrobeSelectPhoto)
                            }
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                        }
                    }
                }

                Section(L10n.wardrobeInfo) {
                    TextField(L10n.wardrobeNamePlaceholder, text: $clothingName)

                    Picker(L10n.wardrobeCategory, selection: $selectedCategory) {
                        ForEach(ClothingCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
            }
            .navigationTitle(L10n.wardrobeAddTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.add) {
                        saveClothing()
                    }
                    .disabled(selectedImage == nil)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
        }
    }

    private func saveClothing() {
        guard let image = selectedImage else { return }

        let name = clothingName.isEmpty ? "\(selectedCategory.displayName) \(Date().formatted(date: .abbreviated, time: .omitted))" : clothingName

        viewModel.addItem(image: image, name: name, category: selectedCategory)
        dismiss()
    }
}

// MARK: - 衣物详情
struct ClothingDetailView: View {
    let item: ClothingItem
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let uiImage = UIImage(data: item.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: item.category.icon)
                            Text(item.category.displayName)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        Text(item.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(L10n.wardrobeAddedOn(item.createdAt.formatted(date: .long, time: .omitted)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    Spacer()

                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(L10n.wardrobeRemove)
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
            .navigationTitle(L10n.wardrobeDetail)
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
}

#Preview {
    WardrobeView()
}
