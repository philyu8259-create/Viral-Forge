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
        let topic = draft.topic.isEmpty ? "早 C 晚 A 焕亮护肤套装" : draft.topic
        let brandPrefix = draft.brandName.isEmpty ? "" : "\(draft.brandName)："
        let templateReason = draft.templateName.isEmpty ? "痛点、结果感和行动理由明确，适合转化型首图标题。" : "套用 \(draft.templateName)，适合快速做系列化内容。"
        let result = ContentResult(
            titles: [
                ScoredLine(text: "\(brandPrefix)熬夜脸别硬遮：这套早 C 晚 A 把光感养回来", score: 94, reason: templateReason),
                ScoredLine(text: "底妆不服帖，先别急着换粉底", score: 91, reason: "用高频痛点降低阅读门槛。"),
                ScoredLine(text: "想要素颜发光感，这 3 个护肤步骤要连起来", score: 89, reason: "清单型标题有保存和转化潜力。")
            ],
            hooks: [
                ScoredLine(text: "很多暗沉不是靠粉底遮掉的，而是前一晚的修护和第二天的打底没接上。", score: 91, reason: "先抓消费痛点，再带出产品。"),
                ScoredLine(text: "这套不是堆瓶子，而是把精华、面霜和补充装做成一个能坚持的焕亮流程。", score: 89, reason: "强调套装价值，降低广告感。")
            ],
            caption: "最近在用这套\(topic)。白天精华打底，晚上面霜修护，再加补充装做长期护理，第二天底妆会更贴，熬夜后的暗沉感也没那么明显。适合想要快速建立护肤仪式感、但不想买一堆单品的人。",
            sellingPoints: ["早 C 晚 A 组合", "熬夜暗沉急救", "上妆更服帖", "补充装更划算"],
            hashtags: ["#护肤套装", "#熬夜脸急救", "#早C晚A", "#小红书种草"]
        )
        var poster = PosterDraft(headline: "熬夜脸别硬遮", subtitle: "早 C 晚 A，把光感养回来", cta: draft.templateName.isEmpty ? "立即解锁焕亮套装" : draft.templateName, style: draft.templateStyle)
        poster.backgroundImageURL = appStorePreviewBackgroundURL()
        if poster.backgroundImageURL != nil {
            poster.productImageIntegratedInBackground = true
        }
        return ContentProject(id: UUID(), createdAt: .now, draft: draft, result: result, poster: poster, isFavorite: false, hasPosterExport: false)
    }

    private func makeEnglishProject(from draft: GenerationDraft) -> ContentProject {
        let topic = draft.topic.isEmpty ? "premium glow skincare launch set" : draft.topic
        let brandPrefix = draft.brandName.isEmpty ? "" : "\(draft.brandName): "
        let templateReason = draft.templateName.isEmpty ? "Clear pain point, visual payoff, and purchase intent." : "Uses \(draft.templateName) as the creative structure."
        let result = ContentResult(
            titles: [
                ScoredLine(text: "\(brandPrefix)Stop covering dull skin. Build glow before makeup.", score: 93, reason: templateReason),
                ScoredLine(text: "I tried a serum + cream glow routine before every makeup day", score: 90, reason: "Personal trial formats perform well on short-form platforms."),
                ScoredLine(text: "Before you buy another base product, fix these 3 prep steps", score: 88, reason: "Decision-helper angle with strong save potential.")
            ],
            hooks: [
                ScoredLine(text: "When foundation sits on top of tired skin, the fix starts before the base layer.", score: 91, reason: "Starts with a relatable beauty problem."),
                ScoredLine(text: "This set turns glow prep into a simple serum, cream, and refill routine.", score: 89, reason: "Practical, credible tone without overclaiming.")
            ],
            caption: "I tried a \(topic) for dull-skin days: serum before the day starts, cream at night, and a refill pouch that makes the routine feel easier to keep. Makeup sits smoother, and the whole set looks premium enough to gift.",
            sellingPoints: ["Serum + cream routine", "Glow-focused prep", "Smoother makeup base", "Premium refill set"],
            hashtags: ["#skincarelaunch", "#glowroutine", "#beautyfinds", "#productreview"]
        )
        var poster = PosterDraft(headline: "Glow before makeup", subtitle: "A premium routine for dull-skin days", cta: draft.templateName.isEmpty ? "Shop the launch set" : draft.templateName, style: draft.templateStyle)
        poster.backgroundImageURL = appStorePreviewBackgroundURL()
        if poster.backgroundImageURL != nil {
            poster.productImageIntegratedInBackground = true
        }
        return ContentProject(id: UUID(), createdAt: .now, draft: draft, result: result, poster: poster, isFavorite: false, hasPosterExport: false)
    }

    private func appStorePreviewBackgroundURL() -> URL? {
        guard let path = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("VF_UI_TEST_APPSTORE_POSTER_BACKGROUND_PATH=") })?
            .replacingOccurrences(of: "VF_UI_TEST_APPSTORE_POSTER_BACKGROUND_PATH=", with: ""),
              !path.isEmpty,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        let mimeType = path.lowercased().hasSuffix(".jpg") || path.lowercased().hasSuffix(".jpeg") ? "image/jpeg" : "image/png"
        return URL(string: "data:\(mimeType);base64,\(data.base64EncodedString())")
    }
}
