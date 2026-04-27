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
        ScrollView {
            VStack(spacing: 20) {
                PosterPreview(poster: poster, platform: project.draft.platform, target: selectedTarget)
                    .frame(height: 520)
                    .padding(.horizontal)

                controls

                QuotaStatusView(quota: appModel.quota, compact: true)
                    .padding(.horizontal)

                Button {
                    Task {
                        if let imageURL = await appModel.generatePosterBackground(for: project, poster: poster, aspectRatio: selectedTarget.apiAspectRatio) {
                            poster.backgroundImageURL = imageURL
                        }
                    }
                } label: {
                    Label(
                        appModel.isGeneratingPosterBackground ? AppText.localized("Generating Background...", "生成背景中...") : AppText.localized("Generate AI Background", "生成 AI 背景"),
                        systemImage: "sparkles.rectangle.stack"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(appModel.isGeneratingPosterBackground)
                .padding(.horizontal)

                if let posterGenerationError = appModel.posterGenerationError {
                    Text(posterGenerationError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    exportPoster()
                } label: {
                    Label(AppText.localized("Render Poster", "生成海报图片"), systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if let exportedImageURL {
                    VStack(spacing: 12) {
                        ShareLink(item: exportedImageURL) {
                            Label(AppText.localized("Share PNG", "分享 PNG 图片"), systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            saveToPhotoLibrary()
                        } label: {
                            Label(
                                isSavingToPhotos ? AppText.localized("Saving...", "保存中...") : AppText.localized("Save to Photos", "保存到相册"),
                                systemImage: "photo.badge.arrow.down"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSavingToPhotos || exportedUIImage == nil)
                    }
                    .padding(.horizontal)
                }

                if let exportStatusMessage {
                    Label(exportStatusMessage, systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let exportedUIImage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.localized("Export Preview", "导出预览"))
                            .font(.headline)
                        Image(uiImage: exportedUIImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.quaternary)
                            }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(AppText.localized("Poster", "海报"))
        .toolbar {
            NavigationLink {
                ResultView(project: project)
            } label: {
                Label(AppText.localized("Content", "文案"), systemImage: "doc.text")
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
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

            TextField(AppText.localized("Headline", "主标题"), text: $poster.headline, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
            TextField(AppText.localized("Subtitle", "副标题"), text: $poster.subtitle)
            TextField(AppText.localized("CTA", "行动按钮"), text: $poster.cta)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
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
            if let backgroundImageURL = poster.backgroundImageURL {
                AsyncImage(url: backgroundImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        palette.background
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

#Preview {
    NavigationStack {
        PosterEditorView(project: SampleData.projects[0])
            .environment(AppModel())
    }
}
