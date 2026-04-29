import SwiftUI
import Photos

private enum PosterExportMode: Hashable {
    case watermarked
    case clean
}

struct PosterEditorView: View {
    @Environment(AppModel.self) private var appModel
    let project: ContentProject

    @State private var poster: PosterDraft
    @State private var exportedUIImage: UIImage?
    @State private var exportedImageURL: URL?
    @State private var exportStatusMessage: String?
    @State private var isSavingToPhotos = false
    @State private var selectedTarget: PosterCanvasTarget
    @State private var exportMode: PosterExportMode = .watermarked

    init(project: ContentProject) {
        self.project = project
        _poster = State(initialValue: project.poster)
        _selectedTarget = State(initialValue: PosterCanvasTarget.defaultTarget(for: project.draft.platform))
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Poster", "海报"),
                subtitle: AppText.localized("Edit, render, and export visual assets", "编辑、生成并导出视觉资产"),
                icon: "photo.on.rectangle.angled",
                tint: VFStyle.platformTint(project.draft.platform)
            )

            VStack(spacing: 18) {
                PosterPreview(
                    poster: poster,
                    platform: project.draft.platform,
                    target: selectedTarget,
                    showsWatermark: showsWatermarkForExport
                )
                    .frame(height: 520)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: VFStyle.platformTint(project.draft.platform).opacity(0.16), radius: 22, x: 0, y: 12)

                controls
                exportOptions

                QuotaStatusView(quota: appModel.quota, compact: true)

                VFPrimaryButton(
                    title: appModel.isGeneratingPosterBackground ? AppText.localized("Generating Background...", "生成背景中...") : AppText.localized("Generate AI Background", "生成 AI 背景"),
                    icon: "sparkles.rectangle.stack",
                    isLoading: appModel.isGeneratingPosterBackground,
                    isEnabled: !appModel.isGeneratingPosterBackground
                ) {
                    Task {
                        if let imageURL = await appModel.generatePosterBackground(for: project, poster: poster, aspectRatio: selectedTarget.apiAspectRatio) {
                            poster.backgroundImageURL = imageURL
                        }
                    }
                }
                .accessibilityIdentifier("vf.poster.generateBackgroundButton")

                if let posterGenerationError = appModel.posterGenerationError {
                    VFGlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(posterGenerationError, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(VFStyle.warning)
                            Text(AppText.localized(
                                "Your poster text and layout are still safe. You can retry AI background generation or render the current poster manually.",
                                "当前海报文案和版式不会丢失。你可以重试 AI 背景，也可以直接生成当前海报。"
                            ))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)

                            Button {
                                Task {
                                    if let imageURL = await appModel.generatePosterBackground(for: project, poster: poster, aspectRatio: selectedTarget.apiAspectRatio) {
                                        poster.backgroundImageURL = imageURL
                                    }
                                }
                            } label: {
                                Label(AppText.localized("Retry AI Background", "重试 AI 背景"), systemImage: "arrow.clockwise")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(VFStyle.primaryRed)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background(VFStyle.primaryRed.opacity(0.10), in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(appModel.isGeneratingPosterBackground)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityIdentifier("vf.poster.backgroundError")
                }

                VFPrimaryButton(
                    title: showsWatermarkForExport
                        ? AppText.localized("Render Branded Poster", "生成带标识图片")
                        : AppText.localized("Render No-Watermark Poster", "生成无水印图片"),
                    icon: "square.and.arrow.down"
                ) {
                    exportPoster()
                }
                .accessibilityIdentifier("vf.poster.renderButton")

                if let exportedImageURL {
                    VFGlassCard {
                        VStack(spacing: 12) {
                            exportResultHeader

                            ShareLink(item: exportedImageURL) {
                                exportActionLabel(AppText.localized("Share PNG", "分享 PNG 图片"), icon: "square.and.arrow.up", tint: VFStyle.primaryRed)
                            }
                            .buttonStyle(.plain)

                            Button {
                                saveToPhotoLibrary()
                            } label: {
                                exportActionLabel(
                                    isSavingToPhotos ? AppText.localized("Saving...", "保存中...") : AppText.localized("Save to Photos", "保存到相册"),
                                    icon: "photo.badge.arrow.down",
                                    tint: VFStyle.ink
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isSavingToPhotos || exportedUIImage == nil)

                            Button {
                                requestCleanExport()
                            } label: {
                                exportActionLabel(
                                    appModel.quota.isPro
                                        ? AppText.localized("Render No-Watermark Copy", "重新生成无水印版")
                                        : AppText.localized("Unlock No-Watermark Export", "解锁无水印导出"),
                                    icon: appModel.quota.isPro ? "checkmark.seal.fill" : "crown.fill",
                                    tint: appModel.quota.isPro ? VFStyle.teal : VFStyle.sunset
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("vf.poster.noWatermarkButton")
                        }
                    }
                }

                if let exportStatusMessage {
                    Label(exportStatusMessage, systemImage: "checkmark.circle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VFStyle.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("vf.poster.exportStatus")
                }

                if let exportedUIImage {
                    VFGlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(AppText.localized("Export Preview", "导出预览"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(VFStyle.ink)
                            Image(uiImage: exportedUIImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(.white.opacity(0.8), lineWidth: 1)
                                }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("vf.poster.screen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink {
                ResultView(project: project)
            } label: {
                Label(AppText.localized("Content", "文案"), systemImage: "doc.text")
            }
        }
        .onAppear {
            if appModel.quota.isPro {
                exportMode = .clean
            }
        }
    }

    private var controls: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Poster Controls", "海报控制台"),
                    subtitle: AppText.localized("Choose size, visual style, and poster copy", "选择尺寸、视觉风格与海报文案")
                )

                Picker(AppText.localized("Template", "模板"), selection: $poster.style) {
                    ForEach(PosterStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                Picker(AppText.localized("Size", "尺寸"), selection: $selectedTarget) {
                    ForEach(PosterCanvasTarget.allCases) { target in
                        Text(target.displayName).tag(target)
                    }
                }
                .pickerStyle(.segmented)

                posterField(AppText.localized("Headline", "主标题"), text: $poster.headline, icon: "textformat.size", tint: VFStyle.primaryRed, lines: 2)
                posterField(AppText.localized("Subtitle", "副标题"), text: $poster.subtitle, icon: "text.alignleft", tint: VFStyle.electricCyan)
                posterField(AppText.localized("CTA", "行动按钮"), text: $poster.cta, icon: "hand.tap.fill", tint: VFStyle.sunset)
            }
        }
    }

    private var exportOptions: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 13) {
                VFSectionHeader(
                    title: AppText.localized("Export Quality", "导出品质"),
                    subtitle: AppText.localized("Free exports include a small ViralForge mark; Pro removes it.", "免费导出带 ViralForge 小标识；会员可无水印。")
                )

                HStack(spacing: 10) {
                    exportModeButton(
                        title: AppText.localized("Branded", "带标识"),
                        subtitle: AppText.localized("Free", "免费"),
                        icon: "sparkles",
                        tint: VFStyle.electricCyan,
                        isSelected: showsWatermarkForExport
                    ) {
                        exportMode = .watermarked
                    }

                    exportModeButton(
                        title: AppText.localized("No Watermark", "无水印"),
                        subtitle: appModel.quota.isPro ? "Pro" : AppText.localized("Pro only", "会员专享"),
                        icon: appModel.quota.isPro ? "checkmark.seal.fill" : "lock.fill",
                        tint: appModel.quota.isPro ? VFStyle.teal : VFStyle.sunset,
                        isSelected: !showsWatermarkForExport
                    ) {
                        if appModel.quota.isPro {
                            exportMode = .clean
                        } else {
                            requestCleanExport()
                        }
                    }
                }
            }
        }
    }

    private var exportResultHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            VFGradientIcon(
                icon: showsWatermarkForExport ? "sparkles" : "checkmark.seal.fill",
                tint: showsWatermarkForExport ? VFStyle.electricCyan : VFStyle.teal,
                size: 34
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(showsWatermarkForExport ? AppText.localized("Branded export ready", "带标识图片已生成") : AppText.localized("No-watermark export ready", "无水印图片已生成"))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                Text(showsWatermarkForExport ? AppText.localized("Upgrade to Pro anytime to remove the ViralForge mark.", "可随时升级 Pro 移除 ViralForge 标识。") : AppText.localized("Ready for direct publishing and client delivery.", "可直接发布或交付客户。"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exportModeButton(title: String, subtitle: String, icon: String, tint: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VFGradientIcon(icon: icon, tint: tint, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                    Text(subtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? tint : VFStyle.secondaryText)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? tint.opacity(0.10) : .white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? tint.opacity(0.34) : .white.opacity(0.78), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func exportActionLabel(_ title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white.opacity(0.62), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            }
    }

    private func posterField(_ placeholder: String, text: Binding<String>, icon: String, tint: Color, lines: Int = 1) -> some View {
        HStack(alignment: lines > 1 ? .top : .center, spacing: 12) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(lines, reservesSpace: lines > 1)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.82), lineWidth: 1)
                }
        }
    }

    private var showsWatermarkForExport: Bool {
        !appModel.quota.isPro || exportMode == .watermarked
    }

    private func requestCleanExport() {
        guard appModel.quota.isPro else {
            appModel.openPaywall(reason: AppText.localized(
                "No-watermark poster export is included in ViralForge Pro.",
                "无水印海报导出是 ViralForge Pro 会员权益。"
            ))
            return
        }

        exportMode = .clean
        exportPoster()
    }

    @MainActor
    private func exportPoster() {
        if exportMode == .clean && !appModel.quota.isPro {
            requestCleanExport()
            return
        }

        let exportSize = selectedTarget.exportSize
        let renderer = ImageRenderer(
            content: PosterPreview(
                poster: poster,
                platform: project.draft.platform,
                target: selectedTarget,
                showsWatermark: showsWatermarkForExport
            )
            .frame(width: exportSize.width, height: exportSize.height)
        )
        renderer.scale = 1
        guard let uiImage = renderer.uiImage else {
            exportStatusMessage = AppText.localized("Poster export failed.", "海报导出失败。")
            return
        }

        exportedUIImage = uiImage
        exportedImageURL = writePNGToTemporaryFile(uiImage)
        exportStatusMessage = showsWatermarkForExport
            ? AppText.localized("Poster rendered with ViralForge mark. It is now available in Assets.", "带 ViralForge 标识的海报已生成，可在素材库查看。")
            : AppText.localized("No-watermark poster rendered. It is now available in Assets.", "无水印海报已生成，可在素材库查看。")

        Task {
            await appModel.savePosterDraft(for: project, poster: poster, markExported: true)
        }
    }

    private func writePNGToTemporaryFile(_ image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }

        let fileName = "viralforge-poster-\(project.id.uuidString).png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            exportStatusMessage = AppText.localized(
                "PNG file export failed: \(error.localizedDescription)",
                "PNG 文件导出失败：\(error.localizedDescription)"
            )
            return nil
        }
    }

    private func saveToPhotoLibrary() {
        guard let exportedUIImage else { return }

        isSavingToPhotos = true
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: exportedUIImage)
        } completionHandler: { success, error in
            Task { @MainActor in
                isSavingToPhotos = false
                if success {
                    exportStatusMessage = AppText.localized("Saved to Photos.", "已保存到相册。")
                } else {
                    exportStatusMessage = AppText.localized(
                        "Photo save failed: \(error?.localizedDescription ?? "Unknown error")",
                        "保存到相册失败：\(error?.localizedDescription ?? "未知错误")"
                    )
                }
            }
        }
    }
}

struct PosterPreview: View {
    let poster: PosterDraft
    let platform: SocialPlatform
    let target: PosterCanvasTarget
    let showsWatermark: Bool

    init(poster: PosterDraft, platform: SocialPlatform, target: PosterCanvasTarget = .xiaohongshuCover, showsWatermark: Bool = false) {
        self.poster = poster
        self.platform = platform
        self.target = target
        self.showsWatermark = showsWatermark
    }

    var body: some View {
        let palette = poster.style.palette

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(palette.background)
            if poster.backgroundImageURL == nil {
                PosterFallbackVisual(palette: palette, platform: platform)
            }
            if let backgroundImageURL = poster.backgroundImageURL {
                AsyncImage(url: backgroundImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        PosterFallbackVisual(palette: palette, platform: platform)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        palette.background
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            LinearGradient(
                colors: [
                    palette.background.opacity(poster.backgroundImageURL == nil ? 0 : 0.08),
                    palette.background.opacity(poster.backgroundImageURL == nil ? 0 : 0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            posterContentOverlay(palette: palette)
            if showsWatermark {
                posterWatermark(palette: palette)
            }
        }
        .aspectRatio(target.aspectRatio, contentMode: .fit)
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    @ViewBuilder
    private func posterContentOverlay(palette: PosterPalette) -> some View {
        switch poster.style {
        case .cleanProduct:
            VStack(alignment: .leading, spacing: 18) {
                platformBadge(palette: palette)
                Spacer()
                posterTitle(palette: palette, size: 44, lineLimit: 3)
                posterSubtitle(palette: palette)
                ctaButton(palette: palette, cornerRadius: 8)
            }
            .padding(28)
        case .boldLaunch:
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    platformBadge(palette: palette)
                    Spacer()
                    Text(AppText.localized("NEW", "上新"))
                        .font(.caption.weight(.black))
                        .foregroundStyle(palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.22), in: Capsule())
                }
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    posterTitle(palette: palette, size: 48, lineLimit: 3)
                    posterSubtitle(palette: palette)
                }
                .padding(18)
                .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 18))
                ctaButton(palette: palette, cornerRadius: 18)
            }
            .padding(26)
        case .softLifestyle:
            VStack(alignment: .leading, spacing: 16) {
                platformBadge(palette: palette)
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    posterTitle(palette: palette, size: 36, lineLimit: 3)
                    posterSubtitle(palette: palette)
                    ctaButton(palette: palette, cornerRadius: 14)
                }
                .padding(18)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.72), lineWidth: 1)
                }
            }
            .padding(24)
        case .editorial:
            VStack(alignment: .leading, spacing: 18) {
                platformBadge(palette: palette)
                Spacer()
                HStack(alignment: .top, spacing: 14) {
                    Rectangle()
                        .fill(palette.accent)
                        .frame(width: 5)
                        .clipShape(Capsule())
                    VStack(alignment: .leading, spacing: 12) {
                        posterTitle(palette: palette, size: 42, lineLimit: 3)
                        posterSubtitle(palette: palette)
                    }
                }
                Text(poster.cta)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(palette.primary)
                    .padding(.bottom, 4)
                    .overlay(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(palette.accent)
                            .frame(height: 3)
                    }
            }
            .padding(28)
        }
    }

    private func platformBadge(palette: PosterPalette) -> some View {
        Text(platform.displayName.uppercased())
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(palette.background)
            .background(palette.accent, in: Capsule())
    }

    private func posterTitle(palette: PosterPalette, size: CGFloat, lineLimit: Int) -> some View {
        Text(poster.headline)
            .font(.system(size: size, weight: .black, design: .rounded))
            .minimumScaleFactor(0.45)
            .lineLimit(lineLimit)
            .foregroundStyle(palette.primary)
    }

    private func posterSubtitle(palette: PosterPalette) -> some View {
        Text(poster.subtitle)
            .font(.title3.weight(.semibold))
            .foregroundStyle(palette.primary.opacity(0.75))
    }

    private func ctaButton(palette: PosterPalette, cornerRadius: CGFloat) -> some View {
        Text(poster.cta)
            .font(.headline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(palette.background)
            .background(palette.accent, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func posterWatermark(palette: PosterPalette) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let markHeight = max(34, width * 0.07)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: max(5, width * 0.008)) {
                        Image(systemName: "sparkles")
                        Text("ViralForge")
                    }
                    .font(.system(size: max(14, width * 0.028), weight: .black, design: .rounded))
                    .foregroundStyle(palette.primary.opacity(0.72))
                    .padding(.horizontal, max(12, width * 0.022))
                    .frame(height: markHeight)
                    .background(.white.opacity(0.66), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.72), lineWidth: max(1, width * 0.0012))
                    }
                    .shadow(color: .black.opacity(0.08), radius: max(8, width * 0.014), x: 0, y: max(4, width * 0.008))
                    .padding(max(18, width * 0.035))
                }
            }
        }
    }
}

private struct PosterFallbackVisual: View {
    let palette: PosterPalette
    let platform: SocialPlatform

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                Circle()
                    .fill(palette.accent.opacity(0.20))
                    .frame(width: width * 0.92, height: width * 0.92)
                    .blur(radius: width * 0.15)
                    .offset(x: -width * 0.34, y: -height * 0.30)

                Circle()
                    .fill(palette.primary.opacity(platform == .douyin || platform == .tikTok ? 0.12 : 0.07))
                    .frame(width: width * 0.78, height: width * 0.78)
                    .blur(radius: width * 0.12)
                    .offset(x: width * 0.30, y: -height * 0.04)

                RoundedRectangle(cornerRadius: width * 0.07)
                    .fill(.white.opacity(platform == .douyin || platform == .tikTok ? 0.14 : 0.70))
                    .frame(width: width * 0.50, height: height * 0.34)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -width * 0.12, y: -height * 0.10)
                    .shadow(color: palette.accent.opacity(0.16), radius: width * 0.08, x: 0, y: width * 0.05)

                RoundedRectangle(cornerRadius: width * 0.08)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.accent.opacity(0.92),
                                palette.primary.opacity(platform == .douyin || platform == .tikTok ? 0.68 : 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width * 0.27, height: height * 0.38)
                    .rotationEffect(.degrees(7))
                    .offset(x: width * 0.18, y: -height * 0.04)
                    .overlay {
                        Image(systemName: fallbackIcon)
                            .font(.system(size: max(28, width * 0.12), weight: .black))
                            .foregroundStyle(.white.opacity(0.90))
                    }
                    .shadow(color: palette.accent.opacity(0.22), radius: width * 0.08, x: 0, y: width * 0.05)

                HStack(spacing: width * 0.035) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index.isMultiple(of: 2) ? palette.accent.opacity(0.70) : .white.opacity(0.72))
                            .frame(width: width * 0.035, height: height * CGFloat([0.13, 0.22, 0.16, 0.26][index]))
                    }
                }
                .rotationEffect(.degrees(18))
                .offset(x: width * 0.28, y: -height * 0.28)
            }
        }
    }

    private var fallbackIcon: String {
        switch platform {
        case .xiaohongshu, .instagram: "camera.fill"
        case .douyin, .tikTok, .youtubeShorts: "play.fill"
        case .weChat: "bubble.left.and.bubble.right.fill"
        }
    }
}

#Preview {
    NavigationStack {
        PosterEditorView(project: SampleData.projects[0])
            .environment(AppModel())
    }
}
