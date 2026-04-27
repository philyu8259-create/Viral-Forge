import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showFavoritesOnly = false

    private var projects: [ContentProject] {
        if showFavoritesOnly {
            appModel.projects.filter(\.isFavorite)
        } else {
            appModel.projects
        }
    }

    var body: some View {
        List {
            Section {
                Toggle(AppText.localized("Favorites only", "只看收藏"), isOn: $showFavoritesOnly)
            }

            Section(AppText.localized("Projects", "项目")) {
                ForEach(projects) { project in
                    NavigationLink {
                        ResultView(project: project)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(project.draft.topic)
                                    .font(.headline)
                                if project.isFavorite {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            Text("\(project.draft.platform.displayName) · \(project.draft.language.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(project.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            if project.poster.backgroundImageURL != nil || project.hasPosterExport {
                                Label(AppText.localized("Poster ready", "海报已保存"), systemImage: "photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { offsets in
                    appModel.deleteProjects(offsets.map { projects[$0] })
                }
            }
        }
        .navigationTitle(AppText.localized("History", "历史"))
        .toolbar {
            EditButton()
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(AppModel())
    }
}
