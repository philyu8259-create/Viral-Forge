import SwiftUI
import Photos

struct PosterEditorView: View {
    @Environment(AppModel.self) private var appModel
    let project: ContentProject

    @State private var poster: PosterDraft
    @State private var exportedUIImage: UIImage?
    @State private var exportedImageURL: URL?
    @State private var exportStatusMessage: String?
    @State private var isSavingToPhotos = false
    @State private var selectedTarget: PosterCanvasTarget

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
                PosterPreview(poster: poster, platform: project.draft.platform, target: selectedTarget)
                    .frame(height: 520)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: VFStyle.platformTint(project.draft.platform).opacity(0.16), radius: 22, x: 0, y: 12)

                controls

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

                VFPrimaryButton(title: AppText.localized("Render Poster", "生成海报图片"), icon: "square.and.arrow.down") {
                    exportPoster()
                }
                .accessibilityIdentifier("vf.poster.renderButton")

                if let exportedImageURL {
                    VFGlassCard {
                        VStack(spacing: 12) {
                        ShareLink(item: exportedImageURL) {
                            Label(AppText.localized("Share PNG", "分享 PNG 图片"), systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(VFStyle.primaryRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.white.opacity(0.62), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            saveToPhotoLibrary()
                        } label: {
                            Label(
                                isSavingToPhotos ? AppText.localized("Saving...", "保存中...") : AppText.localized("Save to Photos", "保存到相册"),
                                systemImage: "photo.badge.arrow.down"
                            )
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(VFStyle.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.62), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(isSavingToPhotos || exportedUIImage == nil)
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

    @MainActor
    private func exportPoster() {
        let exportSize = selectedTarget.exportSize
        let renderer = ImageRenderer(content: PosterPreview(poster: poster, platform: project.draft.platform, target: selectedTarget).frame(width: exportSize.width, height: exportSize.height))
        renderer.scale = 1
        guard let uiImage = renderer.uiImage else {
            exportStatusMessage = AppText.localized("Poster export failed.", "海报导出失败。")
            return
        }

        exportedUIImage = uiImage
        exportedImageURL = writePNGToTemporaryFile(uiImage)
        exportStatusMessage = AppText.localized("Poster rendered. It is now available in Assets.", "海报已生成，可在素材库查看。")

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

    init(poster: PosterDraft, platform: SocialPlatform, target: PosterCanvasTarget = .xiaohongshuCover) {
        self.poster = poster
        self.platform = platform
        self.target = target
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
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(platform.displayName.uppercased())
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(palette.background)
                        .background(palette.accent, in: Capsule())
                    Spacer()
                }

                Spacer()

                Text(poster.headline)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.45)
                    .lineLimit(3)
                    .foregroundStyle(palette.primary)

                Text(poster.subtitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(palette.primary.opacity(0.75))

                Text(poster.cta)
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(palette.background)
                    .background(palette.accent, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(28)
        }
        .aspectRatio(target.aspectRatio, contentMode: .fit)
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
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
