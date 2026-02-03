import Foundation

// MARK: - 微信用户信息
struct WeChatUserInfo: Codable {
    let openID: String
    let nickname: String
    let avatarURL: String
    let gender: Int // 1: 男, 2: 女, 0: 未知

    enum CodingKeys: String, CodingKey {
        case openID = "openid"
        case nickname
        case avatarURL = "headimgurl"
        case gender = "sex"
    }
}

// MARK: - 微信Token响应
struct WeChatTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let openID: String
    let scope: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case openID = "openid"
        case scope
    }
}

// MARK: - 试衣请求
struct TryOnRequest: Codable {
    let personImageBase64: String
    let clothingImageBase64: String

    enum CodingKeys: String, CodingKey {
        case personImageBase64 = "person_image"
        case clothingImageBase64 = "clothing_image"
    }
}

// MARK: - 试衣响应
struct TryOnResponse: Codable {
    let success: Bool
    let resultImageBase64: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case resultImageBase64 = "result_image"
        case message
    }
}

// MARK: - API错误
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        case .decodingError:
            return "数据解析错误"
        case .serverError(let message):
            return "服务器错误：\(message)"
        case .unauthorized:
            return "未授权，请重新登录"
        }
    }
}

// MARK: - 试衣结果
struct TryOnResult: Identifiable {
    let id = UUID()
    let originalPersonImage: Data
    let clothingImage: Data
    let resultImage: Data
    let createdAt: Date
}

// MARK: - 服装类别
enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case tops = "tops"           // 上衣
    case bottoms = "bottoms"     // 裤子
    case dresses = "dresses"     // 连衣裙/裙子
    case outerwear = "outerwear" // 外套
    case shoes = "shoes"         // 鞋子
    case accessories = "accessories" // 配饰

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tops: return L10n.categoryTops
        case .bottoms: return L10n.categoryBottoms
        case .dresses: return L10n.categoryDresses
        case .outerwear: return L10n.categoryOuterwear
        case .shoes: return L10n.categoryShoes
        case .accessories: return L10n.categoryAccessories
        }
    }

    var icon: String {
        switch self {
        case .tops: return "tshirt"
        case .bottoms: return "figure.stand"
        case .dresses: return "figure.dress.line.vertical.figure"
        case .outerwear: return "jacket"
        case .shoes: return "shoe"
        case .accessories: return "handbag"
        }
    }
}

// MARK: - 衣物项
struct ClothingItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: ClothingCategory
    var imageData: Data
    var createdAt: Date
    var tags: [String]

    init(id: UUID = UUID(), name: String, category: ClothingCategory, imageData: Data, tags: [String] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.imageData = imageData
        self.createdAt = Date()
        self.tags = tags
    }

    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 穿搭收藏
struct OutfitCollection: Identifiable, Codable {
    let id: UUID
    var name: String
    var personImageData: Data
    var clothingItems: [UUID]  // 关联的衣物ID
    var resultImageData: Data
    var createdAt: Date
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String = "", personImageData: Data, clothingItems: [UUID], resultImageData: Data) {
        self.id = id
        self.name = name
        self.personImageData = personImageData
        self.clothingItems = clothingItems
        self.resultImageData = resultImageData
        self.createdAt = Date()
        self.isFavorite = true
    }
}

// MARK: - 用户性别
enum UserGender: String, Codable, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return L10n.genderMale
        case .female: return L10n.genderFemale
        case .other: return L10n.genderOther
        }
    }
}

// MARK: - 身体三维数据
struct BodyMeasurements: Codable, Equatable {
    var bust: Double?      // 胸围 (cm)
    var waist: Double?     // 腰围 (cm)
    var hips: Double?      // 臀围 (cm)

    var isEmpty: Bool {
        bust == nil && waist == nil && hips == nil
    }

    var description: String {
        var parts: [String] = []
        if let b = bust { parts.append(L10n.measurementsBust(Int(b))) }
        if let w = waist { parts.append(L10n.measurementsWaist(Int(w))) }
        if let h = hips { parts.append(L10n.measurementsHips(Int(h))) }
        return parts.isEmpty ? L10n.measurementsNotFilled : parts.joined(separator: " / ")
    }
}

// MARK: - 用户资料
struct UserProfile: Codable {
    var fullBodyImageData: Data?   // 全身照
    var gender: UserGender?        // 性别
    var height: Double?            // 身高 (cm)
    var weight: Double?            // 体重 (kg)
    var measurements: BodyMeasurements  // 三维

    init() {
        self.fullBodyImageData = nil
        self.gender = nil
        self.height = nil
        self.weight = nil
        self.measurements = BodyMeasurements()
    }

    var hasFullBodyImage: Bool {
        fullBodyImageData != nil
    }

    var hasBasicInfo: Bool {
        height != nil || weight != nil || gender != nil
    }

    var hasMeasurements: Bool {
        !measurements.isEmpty
    }

    // 生成用于AI的身体描述（提升试衣效果）
    var bodyDescription: String? {
        var parts: [String] = []

        if let g = gender {
            parts.append(g.displayName + "性")
        }
        if let h = height {
            parts.append("身高\(Int(h))cm")
        }
        if let w = weight {
            parts.append("体重\(Int(w))kg")
        }
        if let b = measurements.bust {
            parts.append("胸围\(Int(b))cm")
        }
        if let w = measurements.waist {
            parts.append("腰围\(Int(w))cm")
        }
        if let h = measurements.hips {
            parts.append("臀围\(Int(h))cm")
        }

        return parts.isEmpty ? nil : parts.joined(separator: "，")
    }
}
