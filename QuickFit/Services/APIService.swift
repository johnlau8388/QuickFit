import Foundation

class APIService {
    static let shared = APIService()

    // MARK: - 配置
    private let baseURL = "http://129.226.217.43:8000/api"

    private init() {}

    // MARK: - 微信登录（code换token）
    func wechatLogin(code: String) async throws -> WeChatTokenResponse {
        let url = URL(string: "\(baseURL)/auth/wechat/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["code": code]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(WeChatTokenResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - 获取微信用户信息
    func fetchWeChatUserInfo(accessToken: String, openID: String) async throws -> WeChatUserInfo {
        let url = URL(string: "\(baseURL)/auth/wechat/userinfo?access_token=\(accessToken)&openid=\(openID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(WeChatUserInfo.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - 虚拟试衣
    func tryOnClothing(personImageData: Data, clothingImageData: Data) async throws -> TryOnResponse {
        let url = URL(string: "\(baseURL)/tryon/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // AI生成可能需要较长时间

        let tryOnRequest = TryOnRequest(
            personImageBase64: personImageData.base64EncodedString(),
            clothingImageBase64: clothingImageData.base64EncodedString()
        )

        request.httpBody = try JSONEncoder().encode(tryOnRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(TryOnResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
