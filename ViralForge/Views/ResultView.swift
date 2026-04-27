import SwiftUI
import UIKit

struct ResultView: View {
    @Environment(AppModel.self) private var appModel
    let project: ContentProject
    @State private var regeneratedProject: ContentProject?
    @State private var copyStatusMessage: String?

    private var currentProject: ContentProject {
        appModel.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: currentProject.draft.platform.displayName,
                subtitle: currentProject.draft.topic,
                icon: "sparkles.rectangle.stack.fill",
                tint: VFStyle.platformTint(currentProject.draft.platform)
            )

            metaCard
            reuseSection
            contentSection(AppText.localized("Titles", "标题"), lines: currentProject.result.titles, icon: "textformat", tint: VFStyle.primaryRed)
            contentSection(AppText.localized("Hooks", "开头钩子"), lines: currentProject.result.hooks, icon: "quote.opening", tint: VFStyle.purpleFlow)
            captionSection
            sellingPointsSection
            posterSection
        }
        .accessibilityIdentifier("vf.result.screen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                appModel.toggleFavorite(currentProject)
            } label: {
                Image(systemName: currentProject.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(currentProject.isFavorite ? VFStyle.primaryRed : VFStyle.secondaryText)
            }
            .accessibilityLabel(AppText.localized("Favorite", "收藏"))
        }
        .navigationDestination(item: $regeneratedProject) { project in
            ResultView(project: project)
        }
    }

    private var metaCard: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 10) {
                Text(currentProject.draft.topic)
                    .font(.title3.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                HStack(spacing: 8) {
                    pill(currentProject.draft.language.displayName, tint: VFStyle.electricCyan)
                    pill(currentProject.draft.goal.displayName, tint: VFStyle.sunset)
                    if currentProject.isFavorite {
                        pill(AppText.localized("Favorite", "收藏"), tint: VFStyle.primaryRed)
                    }
                }
            }
        }
    }

    private var reuseSection: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 13) {
                VFSectionHeader(
                    title: AppText.localized("Reuse", "复用"),
                    subtitle: AppText.localized("Turn this result into a poster or regenerate a new pack", "编辑海报或基于当前简报再生成")
                )

                HStack(spacing: 10) {
                    NavigationLink {
                        PosterEditorView(project: currentProject)
                    } label: {
                        actionPill(AppText.localized("Edit Poster", "编辑海报"), icon: "photo.on.rectangle.angled", tint: VFStyle.sunset)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.result.editPosterButton")

                    Button {
                        regenerate()
                    } label: {
                        actionPill(appModel.isGenerating ? AppText.localized("Generating...", "生成中...") : AppText.localized("Regenerate", "再生成"), icon: "arrow.clockwise", tint: VFStyle.primaryRed)
                    }
                    .buttonStyle(.plain)
                    .disabled(appModel.isGenerating)
                }

                HStack(spacing: 10) {
                    Button {
                        copyToClipboard(
                            currentProject.formattedPublishPackage,
                            feedback: AppText.localized("Full publish pack copied.", "整套发布稿已复制。")
                        )
                    } label: {
                        actionPill(AppText.localized("Copy Pack", "复制整套"), icon: "doc.on.doc.fill", tint: VFStyle.electricCyan)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.result.copyPackButton")

                    ShareLink(item: currentProject.formattedPublishPackage) {
                        actionPill(AppText.localized("Share Text", "分享文案"), icon: "square.and.arrow.up", tint: VFStyle.purpleFlow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.result.shareTextButton")
                }

                if let copyStatusMessage {
                    Label(copyStatusMessage, systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VFStyle.teal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let generationError = appModel.generationError {
                    Label(generationError, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VFStyle.warning)
                }
            }
        }
    }

    private func contentSection(_ title: String, lines: [ScoredLine], icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VFSectionHeader(title: title, subtitle: AppText.localized("Copy, compare, and reuse directly", "可直接复制、对比和复用"))
            ForEach(lines) { line in
                VFGlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            VFGradientIcon(icon: icon, tint: tint, size: 34)
                            Text(line.text)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(VFStyle.ink)
                            Spacer()
                            Text("\(line.score)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(tint, in: Capsule())
                        }
                        Text(line.reason)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)
                        copyButton(line.text, tint: tint, feedback: AppText.localized("Line copied.", "已复制该条文案。"))
                    }
                }
            }
        }
    }

    private var captionSection: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 12) {
                VFSectionHeader(title: AppText.localized("Caption", "正文"), subtitle: AppText.localized("Main body copy for publishing", "用于发布的正文内容"))
                Text(currentProject.result.caption)
                    .font(.body.weight(.medium))
                    .foregroundStyle(VFStyle.ink)
                copyButton(currentProject.result.caption, tint: VFStyle.electricCyan, feedback: AppText.localized("Caption copied.", "正文已复制。"))
            }
        }
    }

    private var sellingPointsSection: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VFSectionHeader(title: AppText.localized("Selling Points", "卖点"), subtitle: AppText.localized("Structured arguments and hashtags", "结构化卖点与话题标签"))
                ForEach(currentProject.result.sellingPoints, id: \.self) { point in
                    Label(point, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(VFStyle.ink)
                }
                Text(currentProject.result.hashtags.joined(separator: " "))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)
                copyButton(currentProject.result.hashtags.joined(separator: " "), tint: VFStyle.purpleFlow, feedback: AppText.localized("Hashtags copied.", "标签已复制。"))
            }
        }
    }

    private var posterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VFSectionHeader(title: AppText.localized("Poster", "海报"), subtitle: AppText.localized("Preview and continue editing the visual asset", "预览并继续编辑视觉资产"))
            PosterPreview(poster: currentProject.poster, platform: currentProject.draft.platform)
                .frame(height: 420)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: VFStyle.platformTint(currentProject.draft.platform).opacity(0.14), radius: 20, x: 0, y: 12)
            NavigationLink {
                PosterEditorView(project: currentProject)
            } label: {
                VFPrimaryButton(title: AppText.localized("Edit Poster", "编辑海报"), icon: "photo.on.rectangle.angled") {}
                    .allowsHitTesting(false)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("vf.result.editPosterButton.bottom")
        }
    }

    private func pill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }

    private func actionPill(_ text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
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

    private func copyButton(_ text: String, tint: Color, feedback: String) -> some View {
        Button {
            copyToClipboard(text, feedback: feedback)
        } label: {
            Label(AppText.localized("Copy", "复制"), systemImage: "doc.on.doc")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.58), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func copyToClipboard(_ text: String, feedback: String) {
        UIPasteboard.general.string = text
        withAnimation(.easeOut(duration: 0.16)) {
            copyStatusMessage = feedback
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.16)) {
                copyStatusMessage = nil
            }
        }
    }

    private func regenerate() {
        Task {
            regeneratedProject = await appModel.generateProject(from: currentProject.draft)
        }
    }
}

#Preview {
    NavigationStack {
        ResultView(project: SampleData.projects[0])
            .environment(AppModel())
    }
}
