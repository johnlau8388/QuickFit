import Foundation
import SwiftUI

// MARK: - 支持的语言
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return L10n.settingsLanguageSystem
        case .chinese: return L10n.settingsLanguageZh
        case .english: return L10n.settingsLanguageEn
        }
    }

    var locale: Locale? {
        switch self {
        case .system: return nil
        case .chinese: return Locale(identifier: "zh-Hans")
        case .english: return Locale(identifier: "en")
        }
    }
}

// MARK: - 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private let languageKey = "app_language"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
            updateBundle()
        }
    }

    @Published private(set) var bundle: Bundle = .main

    private init() {
        if let saved = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: saved) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
        updateBundle()
    }

    private func updateBundle() {
        let languageCode: String

        switch currentLanguage {
        case .system:
            // 使用系统语言
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.starts(with: "zh") {
                languageCode = "zh-Hans"
            } else {
                languageCode = "en"
            }
        case .chinese:
            languageCode = "zh-Hans"
        case .english:
            languageCode = "en"
        }

        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = .main
        }
    }

    func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func localizedString(_ key: String, _ args: CVarArg...) -> String {
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, arguments: args)
    }
}

// MARK: - 便捷本地化结构体
struct L10n {
    private static var manager: LanguageManager { LanguageManager.shared }

    static func tr(_ key: String) -> String {
        manager.localizedString(key)
    }

    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = manager.localizedString(key)
        return String(format: format, arguments: args)
    }

    // MARK: - Common
    static var appName: String { tr("app_name") }
    static var cancel: String { tr("cancel") }
    static var confirm: String { tr("confirm") }
    static var save: String { tr("save") }
    static var delete: String { tr("delete") }
    static var done: String { tr("done") }
    static var add: String { tr("add") }
    static var edit: String { tr("edit") }
    static var share: String { tr("share") }
    static var ok: String { tr("ok") }

    // MARK: - Tab Bar
    static var tabTryon: String { tr("tab_tryon") }
    static var tabWardrobe: String { tr("tab_wardrobe") }
    static var tabCollection: String { tr("tab_collection") }
    static var tabProfile: String { tr("tab_profile") }

    // MARK: - Login
    static var loginTitle: String { tr("login_title") }
    static var loginSubtitle: String { tr("login_subtitle") }
    static var loginWechat: String { tr("login_wechat") }
    static var loginTest: String { tr("login_test") }
    static var loginAgreement: String { tr("login_agreement") }
    static var loginAgreementPrefix: String { tr("login_agreement_prefix") }
    static var loginAgreementAnd: String { tr("login_agreement_and") }
    static var loginUserAgreement: String { tr("login_user_agreement") }
    static var loginPrivacyPolicy: String { tr("login_privacy_policy") }
    static var loginPhone: String { tr("login_phone") }
    static var loginPhoneTitle: String { tr("login_phone_title") }
    static var loginPhoneSubtitle: String { tr("login_phone_subtitle") }
    static var loginPhoneNumber: String { tr("login_phone_number") }
    static var loginPhonePlaceholder: String { tr("login_phone_placeholder") }
    static var loginVerificationCode: String { tr("login_verification_code") }
    static var loginCodePlaceholder: String { tr("login_code_placeholder") }
    static var loginSendCode: String { tr("login_send_code") }
    static var loginResendCode: String { tr("login_resend_code") }
    static var loginSubmit: String { tr("login_submit") }
    static var loginPhoneHint: String { tr("login_phone_hint") }
    static func loginPhoneUser(_ suffix: String) -> String { tr("login_phone_user", suffix) }
    static var loginInvalidPhone: String { tr("login_invalid_phone") }
    static var loginInvalidCode: String { tr("login_invalid_code") }
    static var loginSendCodeFailed: String { tr("login_send_code_failed") }
    static var loginWrongCode: String { tr("login_wrong_code") }
    static var loginFailed: String { tr("login_failed") }
    static var loginWechatUnavailable: String { tr("login_wechat_unavailable") }
    static var loginApple: String { tr("login_apple") }
    static var loginAppleUser: String { tr("login_apple_user") }
    static var loginAppleFailed: String { tr("login_apple_failed") }

    // MARK: - Try On
    static var tryonTitle: String { tr("tryon_title") }
    static var tryonMyImage: String { tr("tryon_my_image") }
    static var tryonSetupImage: String { tr("tryon_setup_image") }
    static var tryonSetupImageHint: String { tr("tryon_setup_image_hint") }
    static var tryonSelectClothing: String { tr("tryon_select_clothing") }
    static var tryonFromWardrobe: String { tr("tryon_from_wardrobe") }
    static var tryonUploadImage: String { tr("tryon_upload_image") }
    static var tryonStart: String { tr("tryon_start") }
    static var tryonGenerating: String { tr("tryon_generating") }
    static var tryonResult: String { tr("tryon_result") }
    static var tryonFavorite: String { tr("tryon_favorite") }
    static var tryonFavorited: String { tr("tryon_favorited") }
    static var tryonSaveSuccess: String { tr("tryon_save_success") }
    static var tryonSaveSuccessMsg: String { tr("tryon_save_success_msg") }
    static var tryonFavoriteSuccess: String { tr("tryon_favorite_success") }
    static var tryonFavoriteSuccessMsg: String { tr("tryon_favorite_success_msg") }
    static var tryonAddToWardrobe: String { tr("tryon_add_to_wardrobe") }
    static var tryonAddToWardrobeMsg: String { tr("tryon_add_to_wardrobe_msg") }
    static var tryonAddAndFavorite: String { tr("tryon_add_and_favorite") }
    static func tryonFromWardrobeLabel(_ name: String) -> String { tr("tryon_from_wardrobe_label", name) }
    static var tryonSetupAlertTitle: String { tr("tryon_setup_alert_title") }
    static var tryonSetupAlertGo: String { tr("tryon_setup_alert_go") }
    static var tryonSetupAlertMsg: String { tr("tryon_setup_alert_msg") }

    // MARK: - Wardrobe
    static var wardrobeTitle: String { tr("wardrobe_title") }
    static func wardrobeEmpty(_ category: String) -> String { tr("wardrobe_empty", category) }
    static func wardrobeAdd(_ category: String) -> String { tr("wardrobe_add", category) }
    static var wardrobeAddTitle: String { tr("wardrobe_add_title") }
    static var wardrobePhoto: String { tr("wardrobe_photo") }
    static var wardrobeSelectPhoto: String { tr("wardrobe_select_photo") }
    static var wardrobeInfo: String { tr("wardrobe_info") }
    static var wardrobeNamePlaceholder: String { tr("wardrobe_name_placeholder") }
    static var wardrobeCategory: String { tr("wardrobe_category") }
    static var wardrobeDetail: String { tr("wardrobe_detail") }
    static var wardrobeRemove: String { tr("wardrobe_remove") }
    static func wardrobeAddedOn(_ date: String) -> String { tr("wardrobe_added_on", date) }
    static var wardrobeGoAdd: String { tr("wardrobe_go_add") }

    // MARK: - Categories
    static var categoryTops: String { tr("category_tops") }
    static var categoryBottoms: String { tr("category_bottoms") }
    static var categoryDresses: String { tr("category_dresses") }
    static var categoryOuterwear: String { tr("category_outerwear") }
    static var categoryShoes: String { tr("category_shoes") }
    static var categoryAccessories: String { tr("category_accessories") }

    // MARK: - Collection
    static var collectionTitle: String { tr("collection_title") }
    static var collectionEmpty: String { tr("collection_empty") }
    static var collectionEmptyHint: String { tr("collection_empty_hint") }
    static var collectionOutfit: String { tr("collection_outfit") }
    static var collectionOutfitDetail: String { tr("collection_outfit_detail") }
    static func collectionOutfitPrefix(_ id: String) -> String { tr("collection_outfit_prefix", id) }
    static func collectionItemsCount(_ count: Int) -> String { tr("collection_items_count", count) }
    static var collectionUnfavorite: String { tr("collection_unfavorite") }

    // MARK: - Profile
    static var profileTitle: String { tr("profile_title") }
    static var profileUser: String { tr("profile_user") }
    static var profileWechatUser: String { tr("profile_wechat_user") }
    static var profileMyImage: String { tr("profile_my_image") }
    static var profileImageSet: String { tr("profile_image_set") }
    static var profileUploadPhoto: String { tr("profile_upload_photo") }
    static var profileUploadHint: String { tr("profile_upload_hint") }
    static var profileChangePhoto: String { tr("profile_change_photo") }
    static var profileImageSection: String { tr("profile_image_section") }
    static var profileImageFooter: String { tr("profile_image_footer") }
    static var profileBodyData: String { tr("profile_body_data") }
    static var profileBodyDataHint: String { tr("profile_body_data_hint") }
    static var profileBodySection: String { tr("profile_body_section") }
    static var profileBodyFooter: String { tr("profile_body_footer") }
    static var profileDataSection: String { tr("profile_data_section") }
    static var profileHistory: String { tr("profile_history") }
    static var profileWardrobe: String { tr("profile_wardrobe") }
    static func profileWardrobeCount(_ count: Int) -> String { tr("profile_wardrobe_count", count) }
    static var profileCollection: String { tr("profile_collection") }
    static func profileCollectionCount(_ count: Int) -> String { tr("profile_collection_count", count) }
    static var profileSettingsSection: String { tr("profile_settings_section") }
    static var profileSettings: String { tr("profile_settings") }
    static var profileAboutSection: String { tr("profile_about_section") }
    static var profileVersion: String { tr("profile_version") }
    static var profilePrivacy: String { tr("profile_privacy") }
    static var profileAgreement: String { tr("profile_agreement") }
    static var profileLogout: String { tr("profile_logout") }
    static var profilePhotoSource: String { tr("profile_photo_source") }
    static var profileTakePhoto: String { tr("profile_take_photo") }
    static var profileFromAlbum: String { tr("profile_from_album") }
    static var profileHeight: String { tr("profile_height") }
    static var profileWeight: String { tr("profile_weight") }
    static func profileHeightLabel(_ h: Int) -> String { tr("profile_height_label", h) }
    static func profileWeightLabel(_ w: Int) -> String { tr("profile_weight_label", w) }
    static func profileMeasurements(_ m: String) -> String { tr("profile_measurements", m) }

    // MARK: - Body Info
    static var bodyInfoTitle: String { tr("body_info_title") }
    static var bodyInfoBasic: String { tr("body_info_basic") }
    static var bodyInfoGender: String { tr("body_info_gender") }
    static var bodyInfoGenderUnselected: String { tr("body_info_gender_unselected") }
    static var bodyInfoHeightWeight: String { tr("body_info_height_weight") }
    static var bodyInfoMeasurements: String { tr("body_info_measurements") }
    static var bodyInfoBust: String { tr("body_info_bust") }
    static var bodyInfoWaist: String { tr("body_info_waist") }
    static var bodyInfoHips: String { tr("body_info_hips") }
    static var bodyInfoMeasurementsHint: String { tr("body_info_measurements_hint") }
    static var bodyInfoHowTo: String { tr("body_info_how_to") }
    static var bodyInfoBustTip: String { tr("body_info_bust_tip") }
    static var bodyInfoWaistTip: String { tr("body_info_waist_tip") }
    static var bodyInfoHipsTip: String { tr("body_info_hips_tip") }

    // MARK: - Gender
    static var genderMale: String { tr("gender_male") }
    static var genderFemale: String { tr("gender_female") }
    static var genderOther: String { tr("gender_other") }

    // MARK: - Settings
    static var settingsTitle: String { tr("settings_title") }
    static var settingsNotifications: String { tr("settings_notifications") }
    static var settingsPush: String { tr("settings_push") }
    static var settingsStorage: String { tr("settings_storage") }
    static var settingsAutoSave: String { tr("settings_auto_save") }
    static var settingsCache: String { tr("settings_cache") }
    static var settingsClearCache: String { tr("settings_clear_cache") }
    static var settingsLanguage: String { tr("settings_language") }
    static var settingsLanguageTitle: String { tr("settings_language_title") }
    static var settingsLanguageZh: String { tr("settings_language_zh") }
    static var settingsLanguageEn: String { tr("settings_language_en") }
    static var settingsLanguageSystem: String { tr("settings_language_system") }

    // MARK: - History
    static var historyTitle: String { tr("history_title") }
    static var historyEmpty: String { tr("history_empty") }

    // MARK: - Clothing Image Section
    static var clothingImageSection: String { tr("clothing_image_section") }
    static var addToWardrobeSection: String { tr("add_to_wardrobe_section") }
    static var addToWardrobeHint: String { tr("add_to_wardrobe_hint") }

    // MARK: - Select Clothing
    static var selectClothingTitle: String { tr("select_clothing_title") }

    // MARK: - Measurements
    static var measurementsNotFilled: String { tr("measurements_not_filled") }
    static func measurementsBust(_ v: Int) -> String { tr("measurements_bust", v) }
    static func measurementsWaist(_ v: Int) -> String { tr("measurements_waist", v) }
    static func measurementsHips(_ v: Int) -> String { tr("measurements_hips", v) }
}
