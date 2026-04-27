import SwiftUI

struct ResultView: View {
    @Environment(AppModel.self) private var appModel
    let project: ContentProject
    @State private var regeneratedProject: ContentProject?

    private var currentProject: ContentProject {
        appModel.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                reuseSection
                contentSection(AppText.localized("Titles", "标题"), lines: currentProject.result.titles)
                contentSection(AppText.localized("Hooks", "开头钩子"), lines: currentProject.result.hooks)
                captionSection
                sellingPointsSection
                posterSection
            }
            .padding()
        }
        .navigationTitle(currentProject.draft.platform.displayName)
        .toolbar {
            Button {
                appModel.toggleFavorite(currentProject)
            } label: {
                Image(systemName: currentProject.isFavorite ? "heart.fill" : "heart")
            }
            .accessibilityLabel(AppText.localized("Favorite", "收藏"))
        }
        .navigationDestination(item: $regeneratedProject) { project in
            ResultView(project: project)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentProject.draft.topic)
                .font(.title2.weight(.semibold))
            Text("\(currentProject.draft.language.displayName) · \(currentProject.draft.goal.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var reuseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppText.localized("Reuse", "复用"))
                .font(.headline)

            HStack(spacing: 12) {
                NavigationLink {
                    PosterEditorView(project: currentProject)
                } label: {
                    Label(AppText.localized("Edit Poster", "编辑海报"), systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    regenerate()
                } label: {
                    Label(appModel.isGenerating ? AppText.localized("Generating...", "生成中...") : AppText.localized("Regenerate", "再生成"), systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appModel.isGenerating)
            }

            if let generationError = appModel.generationError {
                Label(generationError, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func contentSection(_ title: String, lines: [ScoredLine]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            ForEach(lines) { line in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(line.text)
                            .font(.body.weight(.medium))
                        Spacer()
                        Text("\(line.score)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                    }
                    Text(line.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    copyButton(line.text)
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppText.localized("Caption", "正文"))
                .font(.headline)
            Text(currentProject.result.caption)
            copyButton(currentProject.result.caption)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var sellingPointsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppText.localized("Selling Points", "卖点"))
                .font(.headline)
            ForEach(currentProject.result.sellingPoints, id: \.self) { point in
                Label(point, systemImage: "checkmark.circle")
            }
            Text(currentProject.result.hashtags.joined(separator: " "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            copyButton(currentProject.result.hashtags.joined(separator: " "))
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var posterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppText.localized("Poster", "海报"))
                .font(.headline)
            PosterPreview(poster: currentProject.poster, platform: currentProject.draft.platform)
                .frame(height: 420)
            NavigationLink {
                PosterEditorView(project: currentProject)
            } label: {
                Label(AppText.localized("Edit Poster", "编辑海报"), systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func copyButton(_ text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
        } label: {
            Label(AppText.localized("Copy", "复制"), systemImage: "doc.on.doc")
        }
        .buttonStyle(.borderless)
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
