import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(AppText.localized("Create", "创作"), systemImage: "sparkles")
            }

            NavigationStack {
                TemplatesView()
            }
            .tabItem {
                Label(AppText.localized("Templates", "模板"), systemImage: "rectangle.on.rectangle")
            }

            NavigationStack {
                BrandKitView()
            }
            .tabItem {
                Label(AppText.localized("Brand", "品牌"), systemImage: "person.text.rectangle")
            }

            NavigationStack {
                AssetsView()
            }
            .tabItem {
                Label(AppText.localized("Assets", "素材"), systemImage: "folder")
            }

            NavigationStack {
                PaywallView()
            }
            .tabItem {
                Label(AppText.localized("Pro", "会员"), systemImage: "crown")
            }
        }
        .tint(VFStyle.primaryRed)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
        .task {
            await appModel.configureStoreKitIfNeeded()
        }
    }
}
