import SwiftUI

@main
struct QuickFitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        TabView {
            TryOnView()
                .tabItem {
                    Image(systemName: "tshirt")
                    Text(L10n.tabTryon)
                }

            WardrobeView()
                .tabItem {
                    Image(systemName: "cabinet")
                    Text(L10n.tabWardrobe)
                }

            CollectionView()
                .tabItem {
                    Image(systemName: "heart")
                    Text(L10n.tabCollection)
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text(L10n.tabProfile)
                }
        }
        .id(languageManager.currentLanguage)
    }
}
