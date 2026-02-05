import SwiftUI
import PhotosUI

struct TryOnView: View {
    @StateObject private var viewModel = TryOnViewModel()
    @ObservedObject private var storage = StorageService.shared
    @State private var showProfileAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 我的形象区域
                    MyImageCard(
                        hasImage: storage.userProfile.hasFullBodyImage,
                        imageData: storage.userProfile.fullBodyImageData,
                        bodyDescription: storage.userProfile.bodyDescription,
                        onSetupTap: { showProfileAlert = true }
                    )

                    // 服装选择区域
                    ClothingSelectionCard(
                        selectedClothing: viewModel.selectedClothingItem,
                        clothingImage: viewModel.clothingImage,
                        onSelectFromWardrobe: { viewModel.showWardrobePicker = true },
                        onUploadNew: { viewModel.showClothingPhotoPicker = true },
                        onClear: { viewModel.clearClothing() }
                    )

                    // 生成按钮
                    Button(action: {
                        viewModel.generateTryOn()
                    }) {
                        HStack {
                            if viewModel.isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isGenerating ? L10n.tryonGenerating : L10n.tryonStart)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            viewModel.canGenerate && !viewModel.isGenerating
                                ? Color.purple
                                : Color.gray
                        )
                        .cornerRadius(27)
                    }
                    .disabled(!viewModel.canGenerate || viewModel.isGenerating)
                    .padding(.horizontal)

                    // 错误提示
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // 生成结果
                    if let resultImage = viewModel.resultImage {
                        TryOnResultCard(
                            image: resultImage,
                            isFavorited: viewModel.isCurrentOutfitFavorited,
                            onSave: { viewModel.saveResultToPhotos() },
                            onShare: { viewModel.shareResult() },
                            onFavorite: { viewModel.handleFavorite() }
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle(L10n.tryonTitle)
            .alert(L10n.tryonSetupAlertTitle, isPresented: $showProfileAlert) {
                Button(L10n.tryonSetupAlertGo) {
                    // 切换到"我的"tab - 这里通过通知或其他方式实现
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.tryonSetupAlertMsg)
            }
            .sheet(isPresented: $viewModel.showClothingPhotoPicker) {
                PhotoPicker(selectedImage: $viewModel.clothingImage)
            }
            .sheet(isPresented: $viewModel.showWardrobePicker) {
                WardrobePickerSheet(onSelect: { item in
                    viewModel.selectFromWardrobe(item)
                })
            }
            .alert(L10n.tryonSaveSuccess, isPresented: $viewModel.showSaveSuccess) {
                Button(L10n.ok, role: .cancel) {}
            } message: {
                Text(L10n.tryonSaveSuccessMsg)
            }
            .alert(L10n.tryonFavoriteSuccess, isPresented: $viewModel.showFavoriteSuccess) {
                Button(L10n.ok, role: .cancel) {}
            } message: {
                Text(L10n.tryonFavoriteSuccessMsg)
            }
            .alert(L10n.tryonAddToWardrobe, isPresented: $viewModel.showAddToWardrobeAlert) {
                Button(L10n.tryonAddAndFavorite) {
                    viewModel.addClothingToWardrobeAndFavorite()
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.tryonAddToWardrobeMsg)
            }
            .sheet(isPresented: $viewModel.showAddClothingSheet) {
                AddClothingBeforeFavoriteSheet(
                    image: viewModel.clothingImage,
                    onSave: { name, category in
                        viewModel.saveClothingAndFavorite(name: name, category: category)
                    },
                    onCancel: {
                        viewModel.showAddClothingSheet = false
                    }
                )
            }
            .fullScreenCover(isPresented: $viewModel.showResultSheet) {
                TryOnResultSheet(
                    image: viewModel.resultImage,
                    isFavorited: viewModel.isCurrentOutfitFavorited,
                    onSave: {
                        viewModel.saveResultToPhotos()
                    },
                    onFavorite: {
                        viewModel.handleFavorite()
                    },
                    onClose: {
                        viewModel.showResultSheet = false
                    }
                )
            }
        }
    }
}

// MARK: - 试衣结果全屏弹窗
struct TryOnResultSheet: View {
    let image: UIImage?
    let isFavorited: Bool
    let onSave: () -> Void
    let onFavorite: () -> Void
    let onClose: () -> Void

    @State private var showSaveSuccess = false

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部关闭按钮
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }

                Spacer()

                // 结果图片
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                } else {
                    Text("图片加载失败")
                        .foregroundColor(.white)
                }

                Spacer()

                // 底部按钮栏
                HStack(spacing: 40) {
                    // 保存按钮
                    Button(action: {
                        onSave()
                        showSaveSuccess = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 28))
                            Text(L10n.save)
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }

                    // 收藏按钮
                    Button(action: onFavorite) {
                        VStack(spacing: 8) {
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .font(.system(size: 28))
                                .foregroundColor(isFavorited ? .red : .white)
                            Text(isFavorited ? L10n.tryonFavorited : L10n.tryonFavorite)
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }

                    // 关闭按钮
                    Button(action: onClose) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 28))
                            Text(L10n.cancel)
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 40)
                .background(Color.black.opacity(0.5))
            }
        }
        .alert(L10n.tryonSaveSuccess, isPresented: $showSaveSuccess) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.tryonSaveSuccessMsg)
        }
    }
}

// MARK: - 我的形象卡片
struct MyImageCard: View {
    let hasImage: Bool
    let imageData: Data?
    let bodyDescription: String?
    let onSetupTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if hasImage, let data = imageData, let uiImage = UIImage(data: data) {
                // 已设置形象
                VStack(spacing: 8) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(L10n.tryonMyImage)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        if let desc = bodyDescription {
                            Text("(\(desc))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                // 未设置形象
                Button(action: onSetupTap) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        Text(L10n.tryonSetupImage)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(L10n.tryonSetupImageHint)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 服装选择卡片
struct ClothingSelectionCard: View {
    let selectedClothing: ClothingItem?
    let clothingImage: UIImage?
    let onSelectFromWardrobe: () -> Void
    let onUploadNew: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let image = clothingImage {
                // 已选择服装
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)

                    // 清除按钮
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }

                // 来源标签
                if let clothing = selectedClothing {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(L10n.tryonFromWardrobeLabel(clothing.name))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // 未选择服装 - 显示两个选项
                VStack(spacing: 16) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)

                    Text(L10n.tryonSelectClothing)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        // 从衣柜选择
                        Button(action: onSelectFromWardrobe) {
                            HStack {
                                Image(systemName: "cabinet")
                                Text(L10n.tryonFromWardrobe)
                            }
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(20)
                        }

                        // 上传新的
                        Button(action: onUploadNew) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text(L10n.tryonUploadImage)
                            }
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(.purple.opacity(0.3))
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 试衣结果卡片
struct TryOnResultCard: View {
    let image: UIImage
    let isFavorited: Bool
    let onSave: () -> Void
    let onShare: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.tryonResult)
                .font(.headline)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
                .cornerRadius(12)

            HStack(spacing: 12) {
                // 收藏按钮
                Button(action: onFavorite) {
                    HStack(spacing: 4) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.subheadline)
                        Text(isFavorited ? L10n.tryonFavorited : L10n.tryonFavorite)
                            .font(.caption)
                    }
                    .foregroundColor(isFavorited ? .red : .purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(isFavorited ? Color.red.opacity(0.1) : Color.purple.opacity(0.1))
                    .cornerRadius(18)
                }

                Button(action: onSave) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.subheadline)
                        Text(L10n.save)
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(18)
                }

                Button(action: onShare) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                        Text(L10n.share)
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(18)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - 衣柜选择器
struct WardrobePickerSheet: View {
    let onSelect: (ClothingItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ClothingCategory = .tops
    @ObservedObject private var storage = StorageService.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分类标签
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ClothingCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category.displayName)
                                    .font(.subheadline)
                                    .fontWeight(selectedCategory == category ? .semibold : .regular)
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.purple : Color(.systemGray6))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }

                // 衣物列表
                let items = storage.getClothingItems(by: selectedCategory)
                if items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedCategory.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(L10n.wardrobeEmpty(selectedCategory.displayName))
                            .foregroundColor(.secondary)
                        Text(L10n.wardrobeGoAdd)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(items) { item in
                                Button {
                                    onSelect(item)
                                    dismiss()
                                } label: {
                                    VStack(spacing: 8) {
                                        if let uiImage = UIImage(data: item.imageData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                        }
                                        Text(item.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.selectClothingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 添加衣物后收藏的表单
struct AddClothingBeforeFavoriteSheet: View {
    let image: UIImage?
    let onSave: (String, ClothingCategory) -> Void
    let onCancel: () -> Void

    @State private var name = ""
    @State private var category: ClothingCategory = .tops
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                if let img = image {
                    Section(L10n.clothingImageSection) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .frame(maxWidth: .infinity)
                    }
                }

                Section(L10n.addToWardrobeSection) {
                    TextField(L10n.wardrobeNamePlaceholder, text: $name)

                    Picker(L10n.wardrobeCategory, selection: $category) {
                        ForEach(ClothingCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                Section {
                    Text(L10n.addToWardrobeHint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(L10n.tryonAddToWardrobe)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tryonAddAndFavorite) {
                        let finalName = name.isEmpty ? "\(category.displayName) \(Date().formatted(date: .abbreviated, time: .omitted))" : name
                        onSave(finalName, category)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TryOnView()
}
