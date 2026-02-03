import Foundation
import Combine
import AuthenticationServices

// MARK: - 统一认证管理器
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    // MARK: - Published 属性
    @Published var isLoggedIn = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - 存储
    private let userDefaults = UserDefaults.standard
    private let userKey = "current_user"
    private let tokenKey = "auth_token"

    private override init() {
        super.init()
        loadStoredUser()
    }

    // MARK: - 加载存储的用户
    private func loadStoredUser() {
        if let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(AppUser.self, from: data) {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }

    // MARK: - 保存用户
    func saveUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: userKey)
        }
        self.currentUser = user
        self.isLoggedIn = true
        self.isLoading = false
        self.errorMessage = nil
    }

    // MARK: - 退出登录
    func logout() {
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: tokenKey)
        currentUser = nil
        isLoggedIn = false
    }

    // MARK: - 测试登录
    func loginAsGuest() {
        let user = AppUser(
            id: "guest_\(UUID().uuidString.prefix(8))",
            nickname: L10n.profileUser,
            avatarURL: nil,
            phone: nil,
            email: nil,
            loginType: .guest
        )
        saveUser(user)
    }

    // MARK: - 微信登录
    func loginWithWeChat() {
        isLoading = true
        errorMessage = nil

        // 检查微信是否安装（实际项目中需要使用 WXApi.isWXAppInstalled()）
        #if DEBUG
        // Debug 模式下模拟登录
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let user = AppUser(
                id: "wechat_\(UUID().uuidString.prefix(8))",
                nickname: "微信用户",
                avatarURL: "https://example.com/avatar.jpg",
                phone: nil,
                email: nil,
                loginType: .wechat
            )
            self.saveUser(user)
        }
        #else
        // Release 模式下显示提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.errorMessage = L10n.loginWechatUnavailable
        }
        #endif
    }

    // MARK: - Apple 登录
    func loginWithApple() {
        isLoading = true
        errorMessage = nil

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    // MARK: - 手机号登录 - 发送验证码
    func sendVerificationCode(phone: String) async -> Bool {
        guard isValidPhoneNumber(phone) else {
            await MainActor.run {
                self.errorMessage = L10n.loginInvalidPhone
            }
            return false
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        // 模拟发送验证码（实际项目中调用后端 API）
        do {
            // 实际项目中：
            // try await APIService.shared.sendSMSCode(phone: phone)

            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 1_000_000_000)

            await MainActor.run {
                self.isLoading = false
            }
            return true
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = L10n.loginSendCodeFailed
            }
            return false
        }
    }

    // MARK: - 手机号登录 - 验证码登录
    func loginWithPhone(phone: String, code: String) async -> Bool {
        guard isValidPhoneNumber(phone) else {
            await MainActor.run {
                self.errorMessage = L10n.loginInvalidPhone
            }
            return false
        }

        guard code.count == 6 else {
            await MainActor.run {
                self.errorMessage = L10n.loginInvalidCode
            }
            return false
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        // 模拟验证登录（实际项目中调用后端 API）
        do {
            // 实际项目中：
            // let response = try await APIService.shared.loginWithPhone(phone: phone, code: code)
            // let user = response.user

            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 1_500_000_000)

            // 模拟验证码验证（测试时任意6位数字都可以）
            let isValidCode = code.count == 6

            if isValidCode {
                let user = AppUser(
                    id: "phone_\(phone.suffix(4))_\(UUID().uuidString.prefix(4))",
                    nickname: L10n.loginPhoneUser(String(phone.suffix(4))),
                    avatarURL: nil,
                    phone: phone,
                    email: nil,
                    loginType: .phone
                )

                await MainActor.run {
                    self.saveUser(user)
                }
                return true
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = L10n.loginWrongCode
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = L10n.loginFailed
            }
            return false
        }
    }

    // MARK: - 验证手机号格式（中国大陆）
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}

// MARK: - Apple 登录代理
extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email

            // 构建用户昵称
            var nickname = L10n.loginAppleUser
            if let givenName = fullName?.givenName {
                nickname = givenName
                if let familyName = fullName?.familyName {
                    nickname = "\(familyName)\(givenName)"
                }
            }

            let user = AppUser(
                id: "apple_\(userIdentifier.prefix(16))",
                nickname: nickname,
                avatarURL: nil,
                phone: nil,
                email: email,
                loginType: .apple
            )

            DispatchQueue.main.async {
                self.saveUser(user)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            if let authError = error as? ASAuthorizationError {
                if authError.code == .canceled {
                    // 用户取消，不显示错误
                } else {
                    self.errorMessage = L10n.loginAppleFailed
                }
            } else {
                self.errorMessage = L10n.loginAppleFailed
            }
        }
    }
}

// MARK: - 用户模型
struct AppUser: Codable, Identifiable {
    let id: String
    var nickname: String
    var avatarURL: String?
    var phone: String?
    var email: String?
    let loginType: LoginType

    enum LoginType: String, Codable {
        case wechat
        case phone
        case apple
        case guest
    }
}
