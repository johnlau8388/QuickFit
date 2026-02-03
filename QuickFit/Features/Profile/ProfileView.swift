import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var storage = StorageService.shared
    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showBodyInfoEditor = false

    var body: some View {
        NavigationView {
            List {
                // 用户信息区域
                Section {
                    HStack(spacing: 16) {
                        // 头像
                        if let avatarURL = authManager.currentUser?.avatarURL,
                           let url = URL(string: avatarURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.purple)
                                .frame(width: 60, height: 60)
                        }

                        // 昵称
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.nickname ?? L10n.profileUser)
                                .font(.headline)

                            Text(loginTypeLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // 我的形象（全身照）
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.crop.rectangle")
                                .foregroundColor(.purple)
                            Text(L10n.profileMyImage)
                                .font(.headline)
                            Spacer()
                            if storage.userProfile.hasFullBodyImage {
                                Text(L10n.profileImageSet)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }

                        if let imageData = storage.userProfile.fullBodyImageData,
                           let uiImage = UIImage(data: imageData) {
                            // 显示已上传的照片
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(12)

                                // 删除按钮
                                Button {
                                    storage.removeFullBodyImage()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .padding(8)
                            }

                            Button {
                                showPhotoOptions = true
                            } label: {
                                Text(L10n.profileChangePhoto)
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                            }
                        } else {
                            // 上传提示
                            Button {
                                showPhotoOptions = true
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.purple)
                                    Text(L10n.profileUploadPhoto)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text(L10n.profileUploadHint)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(L10n.profileImageSection)
                } footer: {
                    Text(L10n.profileImageFooter)
                }

                // 身体数据
                Section {
                    Button {
                        showBodyInfoEditor = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "ruler")
                                        .foregroundColor(.purple)
                                    Text(L10n.profileBodyData)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                // 显示已填写的数据
                                if storage.userProfile.hasBasicInfo || storage.userProfile.hasMeasurements {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let height = storage.userProfile.height {
                                            Text(L10n.profileHeightLabel(Int(height)))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if let weight = storage.userProfile.weight {
                                            Text(L10n.profileWeightLabel(Int(weight)))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if !storage.userProfile.measurements.isEmpty {
                                            Text(L10n.profileMeasurements(storage.userProfile.measurements.description))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    Text(L10n.profileBodyDataHint)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(L10n.profileBodySection)
                } footer: {
                    Text(L10n.profileBodyFooter)
                }

                // 功能列表
                Section(L10n.profileDataSection) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label(L10n.profileHistory, systemImage: "clock")
                    }

                    HStack {
                        Label(L10n.profileWardrobe, systemImage: "cabinet")
                        Spacer()
                        Text(L10n.profileWardrobeCount(storage.wardrobeItems.count))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label(L10n.profileCollection, systemImage: "heart")
                        Spacer()
                        Text(L10n.profileCollectionCount(storage.outfitCollections.count))
                            .foregroundColor(.secondary)
                    }
                }

                // 设置
                Section(L10n.profileSettingsSection) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label(L10n.profileSettings, systemImage: "gearshape")
                    }
                }

                // 关于
                Section(L10n.profileAboutSection) {
                    HStack {
                        Label(L10n.profileVersion, systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label(L10n.profilePrivacy, systemImage: "hand.raised")
                    }

                    NavigationLink {
                        UserAgreementView()
                    } label: {
                        Label(L10n.profileAgreement, systemImage: "doc.text")
                    }
                }

                // 退出登录
                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Text(L10n.profileLogout)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(L10n.profileTitle)
            .confirmationDialog(L10n.profilePhotoSource, isPresented: $showPhotoOptions) {
                Button(L10n.profileTakePhoto) {
                    showCamera = true
                }
                Button(L10n.profileFromAlbum) {
                    showPhotoPicker = true
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .sheet(isPresented: $showPhotoPicker) {
                ProfilePhotoPicker(onImageSelected: { image in
                    storage.setFullBodyImage(image)
                })
            }
            .fullScreenCover(isPresented: $showCamera) {
                ProfileCameraPicker(onImageSelected: { image in
                    storage.setFullBodyImage(image)
                })
            }
            .sheet(isPresented: $showBodyInfoEditor) {
                BodyInfoEditorView()
            }
        }
    }

    private var loginTypeLabel: String {
        guard let user = authManager.currentUser else {
            return L10n.profileUser
        }
        switch user.loginType {
        case .wechat:
            return L10n.profileWechatUser
        case .phone:
            if let phone = user.phone {
                return "+86 \(phone.prefix(3))****\(phone.suffix(4))"
            }
            return L10n.profileUser
        case .apple:
            return L10n.loginAppleUser
        case .guest:
            return L10n.loginTest
        }
    }
}

// MARK: - 照片选择器
struct ProfilePhotoPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfilePhotoPicker

        init(_ parent: ProfilePhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.onImageSelected(image)
                    }
                }
            }
        }
    }
}

// MARK: - 相机拍照
struct ProfileCameraPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileCameraPicker

        init(_ parent: ProfileCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 身体数据编辑器
struct BodyInfoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = StorageService.shared

    @State private var gender: UserGender?
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var bustText = ""
    @State private var waistText = ""
    @State private var hipsText = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(L10n.bodyInfoGender, selection: $gender) {
                        Text(L10n.bodyInfoGenderUnselected).tag(nil as UserGender?)
                        ForEach(UserGender.allCases) { g in
                            Text(g.displayName).tag(g as UserGender?)
                        }
                    }
                } header: {
                    Text(L10n.bodyInfoBasic)
                }

                Section {
                    HStack {
                        Text(L10n.profileHeight)
                        Spacer()
                        TextField("", text: $heightText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(L10n.profileWeight)
                        Spacer()
                        TextField("", text: $weightText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L10n.bodyInfoHeightWeight)
                }

                Section {
                    HStack {
                        Text(L10n.bodyInfoBust)
                        Spacer()
                        TextField("", text: $bustText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(L10n.bodyInfoWaist)
                        Spacer()
                        TextField("", text: $waistText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(L10n.bodyInfoHips)
                        Spacer()
                        TextField("", text: $hipsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L10n.bodyInfoMeasurements)
                } footer: {
                    Text(L10n.bodyInfoMeasurementsHint)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text(L10n.bodyInfoHowTo)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(L10n.bodyInfoBustTip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(L10n.bodyInfoWaistTip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(L10n.bodyInfoHipsTip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(L10n.bodyInfoTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }

    private func loadCurrentProfile() {
        let profile = storage.userProfile
        gender = profile.gender
        if let h = profile.height { heightText = String(Int(h)) }
        if let w = profile.weight { weightText = String(Int(w)) }
        if let b = profile.measurements.bust { bustText = String(Int(b)) }
        if let w = profile.measurements.waist { waistText = String(Int(w)) }
        if let h = profile.measurements.hips { hipsText = String(Int(h)) }
    }

    private func saveProfile() {
        var profile = storage.userProfile
        profile.gender = gender
        profile.height = Double(heightText)
        profile.weight = Double(weightText)
        profile.measurements.bust = Double(bustText)
        profile.measurements.waist = Double(waistText)
        profile.measurements.hips = Double(hipsText)
        storage.updateProfile(profile)
    }
}

// MARK: - 占位视图
struct HistoryView: View {
    var body: some View {
        VStack {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(L10n.historyEmpty)
                .foregroundColor(.secondary)
        }
        .navigationTitle(L10n.historyTitle)
    }
}

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("autoSaveResults") private var autoSaveResults = false
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        List {
            Section(L10n.settingsLanguage) {
                Picker(L10n.settingsLanguage, selection: $languageManager.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section(L10n.settingsNotifications) {
                Toggle(L10n.settingsPush, isOn: $enableNotifications)
            }

            Section(L10n.settingsStorage) {
                Toggle(L10n.settingsAutoSave, isOn: $autoSaveResults)
            }

            Section(L10n.settingsCache) {
                Button(L10n.settingsClearCache) {
                    // 清除缓存逻辑
                }
            }
        }
        .navigationTitle(L10n.settingsTitle)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("""
            隐私政策 / Privacy Policy

            最后更新日期 / Last Updated: 2024年1月 / January 2024

            1. 信息收集 / Information Collection
            我们收集您主动提供的信息，包括：
            We collect information you provide, including:
            - 微信账号信息（昵称、头像）/ WeChat account info (nickname, avatar)
            - 您上传的照片（仅用于试衣功能）/ Photos you upload (for try-on only)
            - 身体数据（仅存储在本地设备）/ Body data (stored locally only)

            2. 信息使用 / Information Usage
            我们使用收集的信息来：/ We use collected information to:
            - 提供虚拟试衣服务 / Provide virtual try-on service
            - 改善用户体验 / Improve user experience

            3. 信息保护 / Information Protection
            我们采取适当的安全措施保护您的个人信息。
            We take appropriate security measures to protect your information.
            您的身体数据仅存储在本地，不会上传到服务器。
            Your body data is stored locally and not uploaded to servers.

            4. 联系我们 / Contact Us
            如有任何问题，请联系：support@example.com
            For any questions, contact: support@example.com
            """)
            .padding()
        }
        .navigationTitle(L10n.profilePrivacy)
    }
}

struct UserAgreementView: View {
    var body: some View {
        ScrollView {
            Text("""
            用户协议 / Terms of Service

            最后更新日期 / Last Updated: 2024年1月 / January 2024

            欢迎使用快穿（QuickFit）！
            Welcome to QuickFit!

            1. 服务说明 / Service Description
            本应用提供AI虚拟试衣服务，帮助您预览服装穿着效果。
            This app provides AI virtual try-on service to preview clothing.

            2. 用户责任 / User Responsibility
            - 您应确保上传的内容合法合规 / Ensure uploaded content is legal
            - 不得上传违法或侵权内容 / Do not upload illegal content

            3. 免责声明 / Disclaimer
            - 试衣效果仅供参考，不代表实际穿着效果
              Try-on results are for reference only
            - 我们不对服装实际尺寸、颜色等负责
              We are not responsible for actual clothing size or color

            4. 知识产权 / Intellectual Property
            本应用的所有内容均受知识产权法保护。
            All content is protected by intellectual property laws.

            5. 协议修改 / Agreement Changes
            我们保留随时修改本协议的权利。
            We reserve the right to modify this agreement.
            """)
            .padding()
        }
        .navigationTitle(L10n.profileAgreement)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
}
