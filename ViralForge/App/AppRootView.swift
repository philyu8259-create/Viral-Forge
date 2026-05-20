import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var createNavigationPath = NavigationPath()
    @State private var createNavigationResetID = UUID()

    var body: some View {
        @Bindable var appModel = appModel

        TabView(selection: $appModel.selectedTab) {
            NavigationStack(path: $createNavigationPath) {
                HomeView()
            }
            .id(createNavigationResetID)
            .tag(AppTab.create)
            .tabItem {
                Label(AppText.localized("Create", "创作"), systemImage: "sparkles")
            }

            NavigationStack {
                AssetsView()
            }
            .tag(AppTab.projects)
            .tabItem {
                Label(AppText.localized("Projects", "项目"), systemImage: "rectangle.stack.fill")
            }

            NavigationStack {
                MyView()
            }
            .tag(AppTab.me)
            .tabItem {
                Label(AppText.localized("Me", "我的"), systemImage: "person.crop.circle")
            }
        }
        .tint(VFStyle.primaryRed)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
        .fullScreenCover(isPresented: $appModel.shouldPresentAppOpenAd) {
            AdSplashPlaceholderView {
                appModel.dismissAppOpenAd()
            }
        }
        #if DEBUG
        .sheet(item: $appModel.debugNativeFeedPlacement) { placement in
            NavigationStack {
                VStack(spacing: 18) {
                    FeedAdPlaceholderView(placement: placement)
                        .padding(.horizontal, 18)
                    Spacer(minLength: 0)
                }
                .padding(.top, 22)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea())
                .navigationTitle(AppText.localized("Feed Ad Test", "信息流广告测试"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(AppText.localized("Done", "完成")) {
                            appModel.debugNativeFeedPlacement = nil
                        }
                    }
                }
            }
        }
        #endif
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task {
                await appModel.configureStoreKitIfNeeded()
                await appModel.bootstrapAds()
            }
        }
        .onChange(of: appModel.createNavigationResetToken) { _, _ in
            appModel.selectedTab = .create
            createNavigationPath = NavigationPath()
            createNavigationResetID = UUID()
        }
        .sheet(isPresented: $appModel.isPaywallPresented) {
            NavigationStack {
                PaywallView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                appModel.isPaywallPresented = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.headline.weight(.bold))
                            }
                            .accessibilityLabel(AppText.localized("Close", "关闭"))
                            .accessibilityIdentifier("vf.paywall.closeButton")
                        }
                    }
            }
        }
    }
}
