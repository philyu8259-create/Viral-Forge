import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        TabView(selection: $appModel.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tag(AppTab.create)
            .tabItem {
                Label(AppText.localized("Create", "创作"), systemImage: "sparkles")
            }

            NavigationStack {
                TemplatesView()
            }
            .tag(AppTab.templates)
            .tabItem {
                Label(AppText.localized("Templates", "模板"), systemImage: "rectangle.on.rectangle")
            }

            NavigationStack {
                BrandKitView()
            }
            .tag(AppTab.brand)
            .tabItem {
                Label(AppText.localized("Brand", "品牌"), systemImage: "person.text.rectangle")
            }

            NavigationStack {
                AssetsView()
            }
            .tag(AppTab.assets)
            .tabItem {
                Label(AppText.localized("Assets", "素材"), systemImage: "folder")
            }

            NavigationStack {
                PaywallView()
            }
            .tag(AppTab.pro)
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
