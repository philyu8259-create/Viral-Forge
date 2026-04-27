import Foundation

struct MockContentService: ContentGenerating {
    func generateContent(from draft: GenerationDraft) async throws -> ContentProject {
        try await Task.sleep(for: .milliseconds(700))

        if draft.language == .chinese {
            return makeChineseProject(from: draft)
        } else {
            return makeEnglishProject(from: draft)
        }
    }

    private func makeChineseProject(from draft: GenerationDraft) -> ContentProject {
        let topic = draft.topic.isEmpty ? "便携榨汁杯" : draft.topic
        let brandPrefix = draft.brandName.isEmpty ? "" : "\(draft.brandName)："
        let templateReason = draft.templateName.isEmpty ? "明确人群和使用场景，带有疑问感。" : "套用 \(draft.templateName)，适合快速做系列化内容。"
        let result = ContentResult(
            titles: [
                ScoredLine(text: "\(brandPrefix)上班族女生真的需要这个\(topic)吗？", score: 92, reason: templateReason),
                ScoredLine(text: "我用了 7 天，才发现\(topic)最该这样选", score: 88, reason: "有体验时间线，适合种草。"),
                ScoredLine(text: "别再乱买了，\(topic)看这 3 点就够", score: 86, reason: "降低决策成本，适合清单型内容。")
            ],
            hooks: [
                ScoredLine(text: "如果你每天都说没时间照顾自己，这个小东西可能比你想的更实用。", score: 90, reason: "先抓生活痛点，再带出产品。"),
                ScoredLine(text: "我以前以为它是智商税，用过之后发现是我场景没选对。", score: 87, reason: "反转开头，提高停留。")
            ],
            caption: "最近试了一个适合通勤和办公室用的\(topic)。它不是那种夸张的神器，更像是把一个小习惯变得更容易坚持：早上带水果，下午直接打一杯，清洗也不用花太多时间。适合想健康一点、但又不想把生活搞复杂的人。",
            sellingPoints: ["通勤包能放下", "清洗步骤少", "适合办公室和健身后", "颜值适合拍照分享"],
            hashtags: ["#小红书种草", "#上班族好物", "#健康生活", "#自律日常"]
        )
        let poster = PosterDraft(headline: "下班后也能轻松补充维C", subtitle: topic, cta: draft.templateName.isEmpty ? "3个场景告诉你值不值得买" : draft.templateName, style: draft.templateStyle)
        return ContentProject(id: UUID(), createdAt: .now, draft: draft, result: result, poster: poster, isFavorite: false, hasPosterExport: false)
    }

    private func makeEnglishProject(from draft: GenerationDraft) -> ContentProject {
        let topic = draft.topic.isEmpty ? "portable blender" : draft.topic
        let brandPrefix = draft.brandName.isEmpty ? "" : "\(draft.brandName): "
        let templateReason = draft.templateName.isEmpty ? "Clear audience and curiosity-driven framing." : "Uses \(draft.templateName) as the creative structure."
        let result = ContentResult(
            titles: [
                ScoredLine(text: "\(brandPrefix)Is this \(topic) actually worth it for busy mornings?", score: 91, reason: templateReason),
                ScoredLine(text: "I tested a \(topic) for 7 days. Here is what surprised me.", score: 89, reason: "Personal trial formats perform well on short-form platforms."),
                ScoredLine(text: "Before you buy a \(topic), check these 3 details.", score: 86, reason: "Decision-helper angle with strong save potential.")
            ],
            hooks: [
                ScoredLine(text: "If your healthy routine keeps failing before 9 AM, the problem might be friction.", score: 90, reason: "Starts with a relatable problem."),
                ScoredLine(text: "I thought this was a gimmick until I used it in the exact right scenario.", score: 87, reason: "Reversal creates attention.")
            ],
            caption: "I tried a \(topic) for busy workdays. It is not magic, but it removes just enough friction to make a small healthy habit easier to repeat. Pack fruit, blend in the afternoon, rinse quickly, and move on.",
            sellingPoints: ["Fits in a work bag", "Quick rinse cleanup", "Useful after workouts", "Easy to photograph for social posts"],
            hashtags: ["#creatorfinds", "#healthyroutine", "#workdayessentials", "#productreview"]
        )
        let poster = PosterDraft(headline: "A smoother routine in 60 seconds", subtitle: topic.capitalized, cta: draft.templateName.isEmpty ? "3 moments where it actually helps" : draft.templateName, style: draft.templateStyle)
        return ContentProject(id: UUID(), createdAt: .now, draft: draft, result: result, poster: poster, isFavorite: false, hasPosterExport: false)
    }
}
