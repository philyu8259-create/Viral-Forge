import SwiftUI
import UIKit

struct AssetsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedSection: AssetSection = .projects
    @State private var assetStatusMessage: String?
    @State private var projectPendingDeletion: ContentProject?
    @State private var posterPendingRemoval: PosterAsset?

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Assets", "素材"),
                subtitle: AppText.localized("Manage generated copy, posters, and reusable snippets", "管理生成文案、海报与可复用片段"),
                icon: "folder.fill",
                tint: VFStyle.sunset
            )

            sectionStrip
            assetStatusBanner

            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(title: selectedSection.displayName, subtitle: sectionSubtitle)

                LazyVStack(spacing: 14) {
                    switch selectedSection {
                    case .projects:
                        projectCards(appModel.projects)
                    case .posters:
                        posterCards(appModel.posterAssets)
                    case .favorites:
                        projectCards(appModel.projects.filter(\.isFavorite))
                    case .snippets:
                        snippetCards(copySnippets)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("vf.assets.screen")
        .task {
            await appModel.refreshProjectsIfNeeded()
        }
        .confirmationDialog(
            AppText.localized("Delete this project?", "删除这个项目？"),
            isPresented: Binding(
                get: { projectPendingDeletion != nil },
                set: { if !$0 { projectPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: projectPendingDeletion
        ) { project in
            Button(AppText.localized("Delete Project", "删除项目"), role: .destructive) {
                appModel.deleteProjects([project])
                projectPendingDeletion = nil
                showAssetStatus(AppText.localized("Project deleted.", "项目已删除。"))
            }
            Button(AppText.localized("Cancel", "取消"), role: .cancel) {
                projectPendingDeletion = nil
            }
        } message: { project in
            Text(AppText.localized(
                "This removes the content pack and linked poster export from this device.",
                "这会从本机移除该内容包和关联海报导出。"
            ) + "\n\(project.draft.topic)")
        }
        .confirmationDialog(
            AppText.localized("Remove this poster export?", "移除这个海报导出？"),
            isPresented: Binding(
                get: { posterPendingRemoval != nil },
                set: { if !$0 { posterPendingRemoval = nil } }
            ),
            titleVisibility: .visible,
            presenting: posterPendingRemoval
        ) { poster in
            Button(AppText.localized("Remove Poster Export", "移除海报导出"), role: .destructive) {
                appModel.removePosterAsset(poster)
                posterPendingRemoval = nil
                showAssetStatus(AppText.localized("Poster export removed.", "海报导出已移除。"))
            }
            Button(AppText.localized("Cancel", "取消"), role: .cancel) {
                posterPendingRemoval = nil
            }
        } message: { poster in
            Text(AppText.localized(
                "The project copy stays available. Only this poster asset is removed from Assets.",
                "项目文案仍会保留，只会从素材里移除该海报资产。"
            ) + "\n\(poster.headline)")
        }
    }

    private var sectionStrip: some View {
        HStack(spacing: 10) {
            ForEach(AssetSection.allCases) { section in
                Button {
                    withAnimation(.snappy) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: section.icon)
                            .font(.headline.weight(.bold))
                        Text(section.displayName)
                            .font(.caption2.weight(.black))
                    }
                    .foregroundStyle(selectedSection == section ? .white : VFStyle.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(selectedSection == section ? section.tint : .white.opacity(0.62))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.78), lineWidth: 1)
                    }
                    .shadow(color: section.tint.opacity(selectedSection == section ? 0.22 : 0.04), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.assets.section.\(section.rawValue)")
            }
        }
    }

    @ViewBuilder
    private var assetStatusBanner: some View {
        if let assetStatusMessage {
            Label(assetStatusMessage, systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(VFStyle.teal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(VFStyle.teal.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(VFStyle.teal.opacity(0.18), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityIdentifier("vf.assets.statusMessage")
        }
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case .projects: AppText.localized("Full generated content packages", "完整生成内容包")
        case .posters: AppText.localized("Rendered and editable poster assets", "已导出或可继续编辑的海报")
        case .favorites: AppText.localized("Pinned high-performing drafts", "已收藏的重点草稿")
        case .snippets: AppText.localized("Copy blocks ready to paste", "可直接复制复用的文案块")
        }
    }

    private var copySnippets: [CopySnippet] {
        appModel.projects.flatMap { project in
            var snippets: [CopySnippet] = []
            snippets.append(contentsOf: project.result.titles.prefix(3).map {
                CopySnippet(project: project, kind: AppText.localized("Title", "标题"), text: $0.text, systemImage: "textformat")
            })
            snippets.append(contentsOf: project.result.hooks.prefix(2).map {
                CopySnippet(project: project, kind: AppText.localized("Hook", "钩子"), text: $0.text, systemImage: "quote.opening")
            })
            if !project.result.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                snippets.append(CopySnippet(project: project, kind: AppText.localized("Caption", "正文"), text: project.result.caption, systemImage: "doc.text.fill"))
            }
            if !project.result.hashtags.isEmpty {
                snippets.append(CopySnippet(project: project, kind: AppText.localized("Hashtags", "标签"), text: project.result.hashtags.joined(separator: " "), systemImage: "number"))
            }
            return snippets
        }
    }

    @ViewBuilder
    private func projectCards(_ projects: [ContentProject]) -> some View {
        if projects.isEmpty {
            emptyCard(
                title: AppText.localized("No assets yet", "暂无素材"),
                subtitle: AppText.localized("Generate your first content pack, then copy, poster, and snippets will appear here.", "先生成第一个内容资产包，之后文案、海报和片段都会出现在这里。"),
                icon: "folder",
                primaryTitle: AppText.localized("Start Creating", "去创作"),
                secondaryTitle: AppText.localized("Browse Templates", "浏览模板")
            )
        } else {
            ForEach(projects) { project in
                ProjectAssetCard(
                    project: project,
                    copy: {
                        UIPasteboard.general.string = project.formattedPublishPackage
                        showAssetStatus(AppText.localized("Publish pack copied.", "整套发布稿已复制。"))
                    },
                    toggleFavorite: {
                        appModel.toggleFavorite(project)
                        showAssetStatus(project.isFavorite ? AppText.localized("Removed from favorites.", "已取消收藏。") : AppText.localized("Added to favorites.", "已加入收藏。"))
                    },
                    requestDelete: {
                        projectPendingDeletion = project
                    }
                )
                .accessibilityIdentifier("vf.assets.projectCard")
            }
        }
    }

    private func posterCopy(for poster: PosterAsset) -> String {
        switch poster.platform {
        case .tikTok, .instagram, .youtubeShorts:
            [
                "Platform: \(poster.platform.displayName)",
                "Topic: \(poster.projectTopic)",
                "",
                "Poster headline",
                poster.headline,
                "",
                "Style: \(poster.style.displayName)"
            ].joined(separator: "\n")
        default:
            [
                "【平台】\(poster.platform.displayName)",
                "【主题】\(poster.projectTopic)",
                "",
                "【海报标题】",
                poster.headline,
                "",
                "【风格】\(poster.style.displayName)"
            ].joined(separator: "\n")
        }
    }

    private func showAssetStatus(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            assetStatusMessage = message
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.2))
            if assetStatusMessage == message {
                withAnimation(.easeOut(duration: 0.16)) {
                    assetStatusMessage = nil
                }
            }
        }
    }

    @ViewBuilder
    private func posterCards(_ posters: [PosterAsset]) -> some View {
        if posters.isEmpty {
            emptyCard(
                title: AppText.localized("No poster exports yet", "暂无海报导出"),
                subtitle: AppText.localized("Open any result, edit the poster, then render a PNG to save it here.", "打开任意生成结果，进入海报编辑器并导出 PNG 后会保存到这里。"),
                icon: "photo",
                primaryTitle: AppText.localized("Create a Pack", "先生成内容"),
                secondaryTitle: AppText.localized("Use a Template", "使用模板")
            )
        } else {
            ForEach(posters) { poster in
                PosterAssetCard(
                    poster: poster,
                    project: appModel.projects.first(where: { $0.id == poster.projectId }),
                    copy: {
                        UIPasteboard.general.string = posterCopy(for: poster)
                        showAssetStatus(AppText.localized("Poster copy copied.", "海报文案已复制。"))
                    },
                    requestRemove: {
                        posterPendingRemoval = poster
                    }
                )
                .accessibilityIdentifier("vf.assets.posterCard")
            }
        }
    }

    @ViewBuilder
    private func snippetCards(_ snippets: [CopySnippet]) -> some View {
        if snippets.isEmpty {
            emptyCard(
                title: AppText.localized("No copy snippets yet", "暂无可复用文案"),
                subtitle: AppText.localized("Titles, hooks, captions, and hashtags from generated projects become reusable snippets.", "生成项目里的标题、钩子、正文和标签会自动变成可复用文案。"),
                icon: "doc.text",
                primaryTitle: AppText.localized("Generate Copy", "生成文案"),
                secondaryTitle: AppText.localized("Pick Template", "选择模板")
            )
        } else {
            ForEach(snippets) { snippet in
                CopySnippetCard(snippet: snippet)
            }
        }
    }

    private func emptyCard(title: String, subtitle: String, icon: String, primaryTitle: String, secondaryTitle: String) -> some View {
        VFGlassCard(level: .thick) {
            VStack(spacing: 13) {
                VFEmptyMomentumVisual(icon: icon, tint: selectedSection.tint, secondary: VFStyle.auroraPink)
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(VFStyle.ink)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    emptyAction(primaryTitle, icon: "sparkles", tint: VFStyle.primaryRed) {
                        appModel.selectedTab = .create
                    }
                    emptyAction(secondaryTitle, icon: "rectangle.3.group", tint: VFStyle.purpleFlow) {
                        appModel.selectedTab = .templates
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .accessibilityIdentifier("vf.assets.emptyState")
    }

    private func emptyAction(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(tint.opacity(0.10), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectAssetCard: View {
    let project: ContentProject
    let copy: () -> Void
    let toggleFavorite: () -> Void
    let requestDelete: () -> Void

    var body: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VFGradientIcon(icon: "doc.text.fill", tint: VFStyle.platformTint(project.draft.platform), size: 38)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(project.draft.topic)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(VFStyle.ink)
                                .lineLimit(2)
                            if project.isFavorite {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(VFStyle.primaryRed)
                            }
                        }
                        Text("\(project.draft.platform.displayName) · \(project.draft.language.displayName)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VFStyle.secondaryText)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        compactAction(icon: "doc.on.doc.fill", tint: VFStyle.electricCyan, action: copy)
                            .accessibilityLabel(AppText.localized("Copy project", "复制项目"))
                            .accessibilityIdentifier("vf.assets.project.copyButton")

                        compactAction(icon: project.isFavorite ? "heart.fill" : "heart", tint: VFStyle.primaryRed, action: toggleFavorite)
                            .accessibilityLabel(project.isFavorite ? AppText.localized("Unfavorite project", "取消收藏项目") : AppText.localized("Favorite project", "收藏项目"))
                            .accessibilityIdentifier("vf.assets.project.favoriteButton")

                        compactAction(icon: "trash", tint: VFStyle.warning, action: requestDelete)
                            .accessibilityLabel(AppText.localized("Delete project", "删除项目"))
                            .accessibilityIdentifier("vf.assets.project.deleteButton")
                    }
                }

                Text(project.result.caption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    assetBadge(AppText.localized("Copy pack", "文案包"), icon: "doc.text", tint: VFStyle.electricCyan)
                    if project.poster.backgroundImageURL != nil || project.hasPosterExport {
                        assetBadge(AppText.localized("Poster ready", "海报可用"), icon: "photo", tint: VFStyle.sunset)
                    }
                    Spacer()
                    Text(project.createdAt, style: .date)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(VFStyle.secondaryText.opacity(0.75))
                }

                HStack(spacing: 8) {
                    NavigationLink {
                        ResultView(project: project)
                    } label: {
                        assetAction(AppText.localized("Open", "打开"), icon: "arrow.up.right", tint: VFStyle.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.assets.project.openButton")

                    Button(action: copy) {
                        assetAction(AppText.localized("Copy", "复制"), icon: "doc.on.doc.fill", tint: VFStyle.electricCyan)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppText.localized("Copy project publish pack", "复制项目文案包"))

                    Button(action: toggleFavorite) {
                        assetAction(project.isFavorite ? AppText.localized("Saved", "已收藏") : AppText.localized("Save", "收藏"), icon: project.isFavorite ? "heart.fill" : "heart", tint: VFStyle.primaryRed)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(project.isFavorite ? AppText.localized("Unfavorite project", "取消收藏项目") : AppText.localized("Favorite project", "收藏项目"))

                    Button(action: requestDelete) {
                        assetAction(AppText.localized("Delete", "删除"), icon: "trash", tint: VFStyle.warning)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppText.localized("Delete project", "删除项目"))
                }
            }
        }
    }

    private func assetBadge(_ text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }

    private func assetAction(_ text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.black))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(tint.opacity(0.08), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.14), lineWidth: 1)
            }
    }

    private func compactAction(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.09), in: Circle())
                .overlay {
                    Circle()
                        .stroke(tint.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct PosterAssetCard: View {
    let poster: PosterAsset
    let project: ContentProject?
    let copy: () -> Void
    let requestRemove: () -> Void

    var body: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    PosterPreview(poster: previewPoster, platform: poster.platform)
                    .frame(width: 78, height: 106)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .shadow(color: VFStyle.platformTint(poster.platform).opacity(0.14), radius: 12, x: 0, y: 7)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(poster.headline)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(VFStyle.ink)
                            .lineLimit(2)
                        Text("\(poster.projectTopic) · \(poster.platform.displayName)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VFStyle.secondaryText)
                            .lineLimit(2)
                        if poster.backgroundImageURL != nil {
                            Label(AppText.localized("AI background", "AI 背景"), systemImage: "sparkles.rectangle.stack")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(VFStyle.purpleFlow)
                        }
                        Text(poster.createdAt, style: .date)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(VFStyle.secondaryText.opacity(0.75))
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    if let project {
                        NavigationLink {
                            PosterEditorView(project: project)
                        } label: {
                            posterAction(AppText.localized("Edit", "编辑"), icon: "slider.horizontal.3", tint: VFStyle.sunset)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("vf.assets.poster.editButton")
                    }

                    Button(action: copy) {
                        posterAction(AppText.localized("Copy", "复制"), icon: "doc.on.doc.fill", tint: VFStyle.electricCyan)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.assets.poster.copyButton")

                    Button(action: requestRemove) {
                        posterAction(AppText.localized("Remove", "移除"), icon: "trash", tint: VFStyle.warning)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.assets.poster.removeButton")
                }
            }
        }
    }

    private var previewPoster: PosterDraft {
        project?.poster ?? PosterDraft(
            headline: poster.headline,
            subtitle: poster.projectTopic,
            cta: poster.platform.posterSafeLabel,
            channelLabel: poster.platform.posterSafeLabel,
            style: poster.style,
            backgroundImageURL: poster.backgroundImageURL
        )
    }

    private func posterAction(_ text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.black))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(tint.opacity(0.08), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.14), lineWidth: 1)
            }
    }
}

private struct CopySnippet: Identifiable {
    let id = UUID()
    let project: ContentProject
    let kind: String
    let text: String
    let systemImage: String
}

private struct CopySnippetCard: View {
    let snippet: CopySnippet
    @State private var didCopy = false

    var body: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(snippet.kind, systemImage: snippet.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.platformTint(snippet.project.draft.platform))
                    Spacer()
                    Text(snippet.project.draft.platform.displayName)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)
                }

                Text(snippet.text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(VFStyle.ink)
                    .lineLimit(4)

                HStack {
                    Text(snippet.project.draft.topic)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = snippet.text
                        didCopy = true
                    } label: {
                        Label(didCopy ? AppText.localized("Copied", "已复制") : AppText.localized("Copy", "复制"), systemImage: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(didCopy ? VFStyle.teal : VFStyle.primaryRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.58), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.assets.snippet.copyButton")
                    .accessibilityLabel(AppText.localized("Copy snippet", "复制文案片段"))
                }
            }
        }
    }
}

private enum AssetSection: String, CaseIterable, Identifiable {
    case projects = "Projects"
    case posters = "Posters"
    case favorites = "Favorites"
    case snippets = "Snippets"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .projects: AppText.localized("Projects", "项目")
        case .posters: AppText.localized("Posters", "海报")
        case .favorites: AppText.localized("Favorites", "收藏")
        case .snippets: AppText.localized("Copy", "文案")
        }
    }

    var icon: String {
        switch self {
        case .projects: "rectangle.stack.fill"
        case .posters: "photo.fill"
        case .favorites: "heart.fill"
        case .snippets: "text.quote"
        }
    }

    var tint: Color {
        switch self {
        case .projects: VFStyle.electricCyan
        case .posters: VFStyle.sunset
        case .favorites: VFStyle.primaryRed
        case .snippets: VFStyle.purpleFlow
        }
    }
}

#Preview {
    NavigationStack {
        AssetsView()
            .environment(AppModel())
    }
}
