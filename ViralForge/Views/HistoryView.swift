import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showFavoritesOnly = false

    private var projects: [ContentProject] {
        showFavoritesOnly ? appModel.projects.filter(\.isFavorite) : appModel.projects
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("History", "历史"),
                subtitle: AppText.localized("Review generated projects and saved posters", "查看历史项目与已保存海报"),
                icon: "clock.arrow.circlepath",
                tint: VFStyle.purpleFlow
            )

            VFGlassCard {
                Toggle(AppText.localized("Favorites only", "只看收藏"), isOn: $showFavoritesOnly)
                    .font(.headline.weight(.bold))
                    .tint(VFStyle.primaryRed)
            }

            LazyVStack(spacing: 14) {
                if projects.isEmpty {
                    VFGlassCard(level: .thick) {
                        VStack(spacing: 12) {
                            VFGradientIcon(icon: "tray", tint: VFStyle.purpleFlow, size: 46)
                            Text(AppText.localized("No history yet", "暂无历史记录"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(VFStyle.ink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                } else {
                    ForEach(projects) { project in
                        NavigationLink {
                            ResultView(project: project)
                        } label: {
                            HistoryProjectCard(project: project) {
                                appModel.deleteProjects([project])
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HistoryProjectCard: View {
    let project: ContentProject
    let delete: () -> Void

    var body: some View {
        VFGlassCard {
            HStack(alignment: .top, spacing: 13) {
                VFGradientIcon(icon: project.poster.backgroundImageURL != nil || project.hasPosterExport ? "photo.fill" : "doc.text.fill", tint: VFStyle.platformTint(project.draft.platform), size: 38)

                VStack(alignment: .leading, spacing: 7) {
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
                    Text(project.createdAt, style: .date)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(VFStyle.secondaryText.opacity(0.72))
                    if project.poster.backgroundImageURL != nil || project.hasPosterExport {
                        Label(AppText.localized("Poster ready", "海报已保存"), systemImage: "photo")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(VFStyle.sunset)
                    }
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
                        .background(.white.opacity(0.54), in: Circle())
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(AppModel())
    }
}
