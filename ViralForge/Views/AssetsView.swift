import SwiftUI
import UIKit

struct AssetsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedSection: AssetSection = .projects

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Assets", "素材"),
                subtitle: AppText.localized("Manage generated copy, posters, and reusable snippets", "管理生成文案、海报与可复用片段"),
                icon: "folder.fill",
                tint: VFStyle.sunset
            )

            sectionStrip

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
        .task {
            await appModel.refreshProjectsIfNeeded()
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
            }
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
            emptyCard(AppText.localized("No assets yet", "暂无素材"), icon: "folder")
        } else {
            ForEach(projects) { project in
                NavigationLink {
                    ResultView(project: project)
                } label: {
                    ProjectAssetCard(project: project) {
                        appModel.deleteProjects([project])
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func posterCards(_ posters: [PosterAsset]) -> some View {
        if posters.isEmpty {
            emptyCard(AppText.localized("No poster exports yet", "暂无海报导出"), icon: "photo")
        } else {
            ForEach(posters) { poster in
                if let project = appModel.projects.first(where: { $0.id == poster.projectId }) {
                    NavigationLink {
                        PosterEditorView(project: project)
                    } label: {
                        PosterAssetCard(poster: poster)
                    }
                    .buttonStyle(.plain)
                } else {
                    PosterAssetCard(poster: poster)
                }
            }
        }
    }

    @ViewBuilder
    private func snippetCards(_ snippets: [CopySnippet]) -> some View {
        if snippets.isEmpty {
            emptyCard(AppText.localized("No copy snippets yet", "暂无可复用文案"), icon: "doc.text")
        } else {
            ForEach(snippets) { snippet in
                CopySnippetCard(snippet: snippet)
            }
        }
    }

    private func emptyCard(_ title: String, icon: String) -> some View {
        VFGlassCard(level: .thick) {
            VStack(spacing: 12) {
                VFGradientIcon(icon: icon, tint: selectedSection.tint, size: 46)
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(VFStyle.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }
}

private struct ProjectAssetCard: View {
    let project: ContentProject
    let delete: () -> Void

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

                    Menu {
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Label(AppText.localized("Delete", "删除"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(VFStyle.secondaryText)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.52), in: Circle())
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
}

private struct PosterAssetCard: View {
    let poster: PosterAsset

    var body: some View {
        VFGlassCard {
            HStack(spacing: 14) {
                PosterPreview(
                    poster: PosterDraft(
                        headline: poster.headline,
                        subtitle: poster.projectTopic,
                        cta: poster.platform.displayName,
                        style: poster.style,
                        backgroundImageURL: poster.backgroundImageURL
                    ),
                    platform: poster.platform
                )
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
