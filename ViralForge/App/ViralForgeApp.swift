import SwiftUI

@main
struct ViralForgeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appModel)
        }
    }
}
