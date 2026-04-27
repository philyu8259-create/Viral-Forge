import SwiftUI

struct AssetsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedSection: AssetSection = .projects

    var body: some View {
        List {
            Section {
                Picker(AppText.localized("Assets", "素材"), selection: $selectedSection) {
                    ForEach(AssetSection.allCases) { section in
                        Text(section.displayName).tag(section)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch selectedSection {
            case .projects:
                projectSection(appModel.projects)
            case .posters:
                posterSection(appModel.posterAssets)
            case .favorites:
                projectSection(appModel.projects.filter(\.isFavorite))
            case .snippets:
                snippetSection(copySnippets)
            }
        }
        .navigationTitle(AppText.localized("Assets", "素材"))
        .toolbar {
            EditButton()
        }
        .task {
            await appModel.refreshProjectsIfNeeded()
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
                snippets.append(CopySnippet(project: project, kind: AppText.localized("Caption", "正文"), text: project.result.caption, systemImage: "doc.text"))
            }
            if !project.result.hashtags.isEmpty {
                snippets.append(CopySnippet(project: project, kind: AppText.localized("Hashtags", "标签"), text: project.result.hashtags.joined(separator: " "), systemImage: "number"))
            }
            return snippets
        }
    }

    private func projectSection(_ projects: [ContentProject]) -> some View {
        Section(selectedSection.displayName) {
            if projects.isEmpty {
                ContentUnavailableView(AppText.localized("No assets yet", "暂无素材"), systemImage: "folder")
            } else {
                ForEach(projects) { project in
                    NavigationLink {
                        ResultView(project: project)
                    } label: {
                        ProjectAssetRow(project: project)
                    }
                }
                .onDelete { offsets in
                    appModel.deleteProjects(offsets.map { projects[$0] })
                }
            }
        }
    }

    private func posterSection(_ posters: [PosterAsset]) -> some View {
        Section(AppText.localized("Poster Exports", "海报导出")) {
            if posters.isEmpty {
                ContentUnavailableView(AppText.localized("No poster exports yet", "暂无海报导出"), systemImage: "photo")
            } else {
                ForEach(posters) { poster in
                    if let project = appModel.projects.first(where: { $0.id == poster.projectId }) {
                        NavigationLink {
                            PosterEditorView(project: project)
                        } label: {
                            posterAssetRow(poster)
                        }
                    } else {
                        posterAssetRow(poster)
                    }
                }
            }
        }
    }

    private func snippetSection(_ snippets: [CopySnippet]) -> some View {
        Section(AppText.localized("Reusable Copy", "可复用文案")) {
            if snippets.isEmpty {
                ContentUnavailableView(AppText.localized("No copy snippets yet", "暂无可复用文案"), systemImage: "doc.text")
            } else {
                ForEach(snippets) { snippet in
                    CopySnippetRow(snippet: snippet)
                }
            }
        }
    }

    private func posterAssetRow(_ poster: PosterAsset) -> some View {
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
            .frame(width: 70, height: 96)

            VStack(alignment: .leading, spacing: 6) {
                Text(poster.headline)
                    .font(.headline)
                Text("\(poster.projectTopic) · \(poster.platform.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if poster.backgroundImageURL != nil {
                    Label(AppText.localized("AI background", "AI 背景"), systemImage: "sparkles.rectangle.stack")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(poster.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ProjectAssetRow: View {
    let project: ContentProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.draft.topic)
                        .font(.headline)
                    Text("\(project.draft.platform.displayName) · \(project.draft.language.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(project.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(project.result.caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                if project.isFavorite {
                    Label(AppText.localized("Favorite", "收藏"), systemImage: "heart.fill")
                }
                if project.poster.backgroundImageURL != nil || project.hasPosterExport {
                    Label(AppText.localized("Poster ready", "海报可用"), systemImage: "photo")
                }
                if !project.result.titles.isEmpty {
                    Label(AppText.localized("Copy pack", "文案包"), systemImage: "doc.text")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct CopySnippet: Identifiable {
    let id = UUID()
    let project: ContentProject
    let kind: String
    let text: String
    let systemImage: String
}

private struct CopySnippetRow: View {
    let snippet: CopySnippet
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(snippet.kind, systemImage: snippet.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snippet.project.draft.platform.displayName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(snippet.text)
                .font(.body)
                .lineLimit(4)

            HStack {
                Text(snippet.project.draft.topic)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button {
                    UIPasteboard.general.string = snippet.text
                    didCopy = true
                } label: {
                    Label(didCopy ? AppText.localized("Copied", "已复制") : AppText.localized("Copy", "复制"), systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
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
}

#Preview {
    NavigationStack {
        AssetsView()
            .environment(AppModel())
    }
}
