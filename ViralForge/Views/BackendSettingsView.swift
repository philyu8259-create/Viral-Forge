import SwiftUI

struct BackendSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var settings = BackendSettings()

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Backend", "后端"),
                subtitle: AppText.localized("Configure data source and development endpoint", "配置数据来源与开发接口"),
                icon: "server.rack",
                tint: VFStyle.electricCyan
            )

            modeCard
            backendCard
            connectionCard
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settings = appModel.backendSettings
        }
    }

    private var modeCard: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Mode", "模式"),
                    subtitle: AppText.localized("Choose local mock data or live backend", "选择本地 Mock 或真实后端")
                )

                Picker(AppText.localized("Data source", "数据来源"), selection: $settings.mode) {
                    ForEach(BackendMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var backendCard: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Backend", "后端"),
                    subtitle: AppText.localized("Debug can use localhost; release needs public HTTPS", "调试可用 localhost，正式包需要公网 HTTPS")
                )

                glassField(AppText.localized("Base URL", "后端地址"), text: $settings.baseURLString, icon: "link", tint: VFStyle.electricCyan)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                glassField(AppText.localized("User ID", "用户 ID"), text: $settings.userId, icon: "person.crop.circle.fill", tint: VFStyle.purpleFlow)
                    .textInputAutocapitalization(.never)

                Text(AppText.localized("Debug builds can use http://localhost:8787. TestFlight and App Store builds must use the public HTTPS backend URL.", "调试包可使用 http://localhost:8787。TestFlight 和 App Store 包必须填写公网 HTTPS 后端地址。"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)
            }
        }
    }

    private var connectionCard: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label(appModel.backendStatusMessage, systemImage: statusIcon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(statusColor)
                    .fixedSize(horizontal: false, vertical: true)

                if statusIsError {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(VFStyle.sunset)
                        Text(AppText.localized(
                            "You can switch to Mock mode to keep using the app while the backend is down.",
                            "后端不可用时，可以切回 Mock 模式继续使用 App。"
                        ))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                    }
                    .padding(12)
                    .background(VFStyle.sunset.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                }

                VFPrimaryButton(
                    title: AppText.localized("Save Settings", "保存设置"),
                    icon: "checkmark.circle"
                ) {
                    appModel.updateBackendSettings(settings)
                }

                HStack(spacing: 10) {
                    secondaryButton(AppText.localized("Test Connection", "测试连接"), icon: "network", isEnabled: !appModel.isSyncingBackend && settings.mode == .backend) {
                        appModel.updateBackendSettings(settings)
                        Task { await appModel.testBackendConnection() }
                    }

                    secondaryButton(appModel.isSyncingBackend ? AppText.localized("Syncing...", "同步中...") : AppText.localized("Sync Data", "同步数据"), icon: "arrow.triangle.2.circlepath", isEnabled: !appModel.isSyncingBackend && settings.mode == .backend) {
                        appModel.updateBackendSettings(settings)
                        Task { await appModel.syncFromBackend() }
                    }
                }
            }
        }
    }

    private var statusIcon: String {
        if statusIsError {
            return "xmark.octagon.fill"
        }
        if appModel.backendStatusMessage.localizedCaseInsensitiveContains("synced")
            || appModel.backendStatusMessage.localizedCaseInsensitiveContains("ok")
            || appModel.backendStatusMessage.localizedCaseInsensitiveContains("saved") {
            return "checkmark.circle.fill"
        }
        return "server.rack"
    }

    private var statusColor: Color {
        statusIsError ? VFStyle.warning : VFStyle.secondaryText
    }

    private var statusIsError: Bool {
        let message = appModel.backendStatusMessage.lowercased()
        return message.contains("failed")
            || message.contains("invalid")
            || message.contains("unreachable")
            || message.contains("不可用")
            || message.contains("无效")
            || message.contains("失败")
    }

    private func glassField(_ placeholder: String, text: Binding<String>, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            TextField(placeholder, text: text)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.82), lineWidth: 1)
                }
        }
    }

    private func secondaryButton(_ title: String, icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(isEnabled ? VFStyle.ink : VFStyle.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(isEnabled ? 0.62 : 0.38), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.78), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    NavigationStack {
        BackendSettingsView()
            .environment(AppModel())
    }
}
