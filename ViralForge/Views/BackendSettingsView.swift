import SwiftUI

struct BackendSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var settings = BackendSettings()

    var body: some View {
        Form {
            Section(AppText.localized("Mode", "模式")) {
                Picker(AppText.localized("Data source", "数据来源"), selection: $settings.mode) {
                    ForEach(BackendMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                TextField(AppText.localized("Base URL", "后端地址"), text: $settings.baseURLString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                TextField(AppText.localized("User ID", "用户 ID"), text: $settings.userId)
                    .textInputAutocapitalization(.never)
            } header: {
                Text(AppText.localized("Backend", "后端"))
            } footer: {
                Text(AppText.localized("Debug builds can use http://localhost:8787. TestFlight and App Store builds must use the public HTTPS backend URL.", "调试包可使用 http://localhost:8787。TestFlight 和 App Store 包必须填写公网 HTTPS 后端地址。"))
            }

            Section(AppText.localized("Connection", "连接")) {
                Label(appModel.backendStatusMessage, systemImage: statusIcon)
                    .foregroundStyle(statusColor)

                Button {
                    appModel.updateBackendSettings(settings)
                } label: {
                    Label(AppText.localized("Save Settings", "保存设置"), systemImage: "checkmark.circle")
                }

                Button {
                    appModel.updateBackendSettings(settings)
                    Task { await appModel.testBackendConnection() }
                } label: {
                    Label(AppText.localized("Test Connection", "测试连接"), systemImage: "network")
                }
                .disabled(appModel.isSyncingBackend || settings.mode != .backend)

                Button {
                    appModel.updateBackendSettings(settings)
                    Task { await appModel.syncFromBackend() }
                } label: {
                    Label(appModel.isSyncingBackend ? AppText.localized("Syncing...", "同步中...") : AppText.localized("Sync Backend Data", "同步后端数据"), systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(appModel.isSyncingBackend || settings.mode != .backend)
            }
        }
        .navigationTitle(AppText.localized("Backend", "后端"))
        .onAppear {
            settings = appModel.backendSettings
        }
    }

    private var statusIcon: String {
        if appModel.backendStatusMessage.localizedCaseInsensitiveContains("failed") {
            return "xmark.octagon"
        }
        if appModel.backendStatusMessage.localizedCaseInsensitiveContains("synced")
            || appModel.backendStatusMessage.localizedCaseInsensitiveContains("ok")
            || appModel.backendStatusMessage.localizedCaseInsensitiveContains("saved") {
            return "checkmark.circle"
        }
        return "server.rack"
    }

    private var statusColor: Color {
        appModel.backendStatusMessage.localizedCaseInsensitiveContains("failed") ? .red : .secondary
    }
}

#Preview {
    NavigationStack {
        BackendSettingsView()
            .environment(AppModel())
    }
}
