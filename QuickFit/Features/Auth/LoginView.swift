import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var agreedToTerms = true
    @State private var showPrivacyPolicy = false
    @State private var showUserAgreement = false
    @State private var showPhoneLogin = false

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo和标题
                VStack(spacing: 16) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)

                    Text(L10n.loginTitle)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text(L10n.loginSubtitle)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // 登录按钮区域
                VStack(spacing: 16) {
                    // 微信登录按钮
                    Button(action: {
                        authManager.loginWithWeChat()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "message.fill")
                                .font(.title2)
                            Text(L10n.loginWechat)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(agreedToTerms ? Color(red: 0.07, green: 0.73, blue: 0.31) : Color.gray)
                        .cornerRadius(28)
                    }
                    .disabled(authManager.isLoading || !agreedToTerms)

                    // 手机号登录按钮
                    Button(action: {
                        showPhoneLogin = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .font(.title2)
                            Text(L10n.loginPhone)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(agreedToTerms ? Color.orange : Color.gray)
                        .cornerRadius(28)
                    }
                    .disabled(authManager.isLoading || !agreedToTerms)

                    // Apple 登录按钮
                    Button(action: {
                        authManager.loginWithApple()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                            Text(L10n.loginApple)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(agreedToTerms ? Color.black : Color.gray)
                        .cornerRadius(28)
                    }
                    .disabled(authManager.isLoading || !agreedToTerms)

                    // 测试登录按钮
                    Button(action: {
                        authManager.loginAsGuest()
                    }) {
                        Text(L10n.loginTest)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(agreedToTerms ? Color.white.opacity(0.2) : Color.gray.opacity(0.3))
                            .cornerRadius(22)
                    }
                    .disabled(!agreedToTerms)

                    // 加载指示器
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }

                    // 错误信息
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }

                    // 用户协议勾选
                    HStack(spacing: 8) {
                        Button(action: {
                            agreedToTerms.toggle()
                        }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundColor(agreedToTerms ? .white : .white.opacity(0.6))
                        }

                        Text(L10n.loginAgreementPrefix)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            showUserAgreement = true
                        }) {
                            Text(L10n.loginUserAgreement)
                                .font(.caption)
                                .foregroundColor(.white)
                                .underline()
                        }

                        Text(L10n.loginAgreementAnd)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            showPrivacyPolicy = true
                        }) {
                            Text(L10n.loginPrivacyPolicy)
                                .font(.caption)
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            LoginPrivacyPolicyView()
        }
        .sheet(isPresented: $showUserAgreement) {
            LoginUserAgreementView()
        }
        .sheet(isPresented: $showPhoneLogin) {
            PhoneLoginView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - 手机号登录视图
struct PhoneLoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var phone = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var countdown = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text(L10n.loginPhoneTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(L10n.loginPhoneSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // 手机号输入
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.loginPhoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("+86")
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)

                        TextField(L10n.loginPhonePlaceholder, text: $phone)
                            .keyboardType(.phonePad)
                            .padding(.vertical, 16)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // 验证码输入
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.loginVerificationCode)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        TextField(L10n.loginCodePlaceholder, text: $code)
                            .keyboardType(.numberPad)
                            .padding(.leading, 16)
                            .padding(.vertical, 16)

                        Button(action: {
                            sendCode()
                        }) {
                            Text(countdown > 0 ? "\(countdown)s" : (codeSent ? L10n.loginResendCode : L10n.loginSendCode))
                                .font(.subheadline)
                                .foregroundColor(canSendCode ? .orange : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .disabled(!canSendCode)
                        .padding(.trailing, 8)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // 登录按钮
                Button(action: {
                    login()
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text(L10n.loginSubmit)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canLogin ? Color.orange : Color.gray)
                    .cornerRadius(27)
                }
                .disabled(!canLogin || authManager.isLoading)
                .padding(.horizontal)

                // 错误信息
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()

                // 提示
                Text(L10n.loginPhoneHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .navigationTitle(L10n.loginPhone)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var canSendCode: Bool {
        phone.count == 11 && countdown == 0 && !authManager.isLoading
    }

    private var canLogin: Bool {
        phone.count == 11 && code.count == 6
    }

    private func sendCode() {
        Task {
            let success = await authManager.sendVerificationCode(phone: phone)
            if success {
                await MainActor.run {
                    codeSent = true
                    startCountdown()
                }
            }
        }
    }

    private func startCountdown() {
        countdown = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    private func login() {
        Task {
            let success = await authManager.loginWithPhone(phone: phone, code: code)
            if success {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - 登录页隐私政策视图
struct LoginPrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text("""
                隐私政策 / Privacy Policy

                最后更新日期 / Last Updated: 2024年1月 / January 2024

                1. 信息收集 / Information Collection
                我们收集您主动提供的信息，包括：
                We collect information you provide, including:
                - 微信账号信息（昵称、头像）/ WeChat account info (nickname, avatar)
                - 手机号码 / Phone number
                - 您上传的照片（仅用于试衣功能）/ Photos you upload (for try-on only)
                - 身体数据（仅存储在本地设备）/ Body data (stored locally only)

                2. 信息使用 / Information Usage
                我们使用收集的信息来：/ We use collected information to:
                - 提供虚拟试衣服务 / Provide virtual try-on service
                - 发送验证码 / Send verification codes
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
            .navigationTitle(L10n.loginPrivacyPolicy)
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

// MARK: - 登录页用户协议视图
struct LoginUserAgreementView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
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
            .navigationTitle(L10n.loginUserAgreement)
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
    LoginView()
        .environmentObject(AuthManager.shared)
}
