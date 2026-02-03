import Foundation
import Combine

// MARK: - 微信SDK协议（实际项目中需要导入WechatOpenSDK）
// import WechatOpenSDK

class WeChatAuthManager: NSObject, ObservableObject {
    static let shared = WeChatAuthManager()

    // MARK: - 配置信息（请替换为你的实际配置）
    private let appID = "YOUR_WECHAT_APP_ID"
    private let appSecret = "YOUR_WECHAT_APP_SECRET"
    private let universalLink = "https://your-domain.com/app/"

    // MARK: - Published 属性
    @Published var isLoggedIn = false
    @Published var userInfo: WeChatUserInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - 存储
    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "wechat_access_token"
    private let refreshTokenKey = "wechat_refresh_token"
    private let openIDKey = "wechat_openid"

    private override init() {
        super.init()
        loadStoredCredentials()
    }

    // MARK: - 注册微信SDK
    func registerApp() {
        // 实际项目中取消注释以下代码：
        // WXApi.registerApp(appID, universalLink: universalLink)
        print("[WeChat] App registered with ID: \(appID)")
    }

    // MARK: - 发起微信登录
    func login() {
        isLoading = true
        errorMessage = nil

        // 实际项目中取消注释以下代码：
        /*
        let req = SendAuthReq()
        req.scope = "snsapi_userinfo"
        req.state = UUID().uuidString
        WXApi.send(req) { success in
            if !success {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "无法打开微信"
                }
            }
        }
        */

        // 模拟登录（开发测试用）
        #if DEBUG
        simulateLogin()
        #endif
    }

    // MARK: - 处理微信回调URL
    func handleOpenURL(_ url: URL) -> Bool {
        // 实际项目中取消注释以下代码：
        // return WXApi.handleOpen(url, delegate: self)
        return true
    }

    // MARK: - 微信授权回调处理
    func onAuthResponse(code: String) {
        // 用code换取access_token
        Task {
            await exchangeCodeForToken(code: code)
        }
    }

    // MARK: - 用code换取access_token
    private func exchangeCodeForToken(code: String) async {
        do {
            let tokenResponse = try await APIService.shared.wechatLogin(code: code)
            await MainActor.run {
                self.saveCredentials(
                    accessToken: tokenResponse.accessToken,
                    refreshToken: tokenResponse.refreshToken,
                    openID: tokenResponse.openID
                )
            }
            // 获取用户信息
            await fetchUserInfo(accessToken: tokenResponse.accessToken, openID: tokenResponse.openID)
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "登录失败：\(error.localizedDescription)"
            }
        }
    }

    // MARK: - 获取用户信息
    private func fetchUserInfo(accessToken: String, openID: String) async {
        do {
            let userInfo = try await APIService.shared.fetchWeChatUserInfo(
                accessToken: accessToken,
                openID: openID
            )
            await MainActor.run {
                self.userInfo = userInfo
                self.isLoggedIn = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "获取用户信息失败"
            }
        }
    }

    // MARK: - 退出登录
    func logout() {
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.removeObject(forKey: openIDKey)
        userInfo = nil
        isLoggedIn = false
    }

    // MARK: - 存储凭证
    private func saveCredentials(accessToken: String, refreshToken: String, openID: String) {
        userDefaults.set(accessToken, forKey: accessTokenKey)
        userDefaults.set(refreshToken, forKey: refreshTokenKey)
        userDefaults.set(openID, forKey: openIDKey)
    }

    // MARK: - 加载存储的凭证
    private func loadStoredCredentials() {
        if let _ = userDefaults.string(forKey: accessTokenKey),
           let _ = userDefaults.string(forKey: openIDKey) {
            // 验证token有效性后设置登录状态
            // 简化处理：如果有存储的凭证，认为已登录
            isLoggedIn = true
            // 可以在这里刷新用户信息
        }
    }

    // MARK: - 模拟登录（开发测试用）
    #if DEBUG
    private func simulateLogin() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.userInfo = WeChatUserInfo(
                openID: "test_openid_123",
                nickname: "测试用户",
                avatarURL: "https://example.com/avatar.jpg",
                gender: 1
            )
            self.isLoggedIn = true
            self.isLoading = false
        }
    }
    #endif

    // MARK: - 测试登录（无需微信，直接进入应用）
    func loginAsGuest() {
        self.userInfo = WeChatUserInfo(
            openID: "test_\(UUID().uuidString.prefix(8))",
            nickname: "测试用户",
            avatarURL: "",
            gender: 0
        )
        self.isLoggedIn = true
    }
}

// MARK: - WXApiDelegate
/*
extension WeChatAuthManager: WXApiDelegate {
    func onResp(_ resp: BaseResp) {
        if let authResp = resp as? SendAuthResp {
            if authResp.errCode == 0, let code = authResp.code {
                onAuthResponse(code: code)
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "微信授权失败"
                }
            }
        }
    }
}
*/
