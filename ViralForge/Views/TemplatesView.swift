import SwiftUI

struct TemplatesView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: TemplateCategory = .productSeeding

    private var filteredTemplates: [CreativeTemplate] {
        appModel.visibleTemplates.filter { $0.category == selectedCategory }
    }

    private var visualTemplateCount: Int {
        appModel.visibleTemplates.filter(\.isVisualTemplate).count
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Templates", "模板"),
                subtitle: AppText.localized(
                    "\(appModel.visibleTemplates.count) workflows, \(visualTemplateCount) visual templates",
                    "\(appModel.visibleTemplates.count) 个工作流，其中 \(visualTemplateCount) 个视觉模板"
                ),
                icon: "rectangle.on.rectangle.fill",
                tint: VFStyle.purpleFlow
            )

            categoryStrip

            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Template Library", "模板库"),
                    subtitle: AppText.localized(
                        "\(filteredTemplates.count) templates in this category. Pick one, fill the product, and generate a structured pack.",
                        "当前类目 \(filteredTemplates.count) 个模板。选择模板，填入产品，一键生成结构化内容包。"
                    )
                )

                LazyVStack(spacing: 14) {
                    ForEach(Array(filteredTemplates.enumerated()), id: \.element.id) { index, template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("vf.templateCard.\(template.name)")

                        if shouldInsertFeedAd(after: index, total: filteredTemplates.count),
                           let adPlacement = templateFeedPlacement {
                            FeedAdPlaceholderView(placement: adPlacement)
                                .accessibilityIdentifier("vf.templates.list.adCard")
                        }
                    }
                }
            }

            VFGlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label(AppText.localized("Viral Template Studio", "爆款模板工作台"), systemImage: "sparkles.rectangle.stack")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)

                    VStack(spacing: 12) {
                        moduleRow(AppText.localized("Six monetization-focused template modules", "六类变现导向模板模块"), icon: "rectangle.3.group", tint: VFStyle.primaryRed)
                        moduleRow(AppText.localized("Built-in audience, tone, and content structure", "内置人群、语气和内容结构"), icon: "list.bullet.rectangle", tint: VFStyle.electricCyan)
                        moduleRow(AppText.localized("One template can produce copy, poster or image direction, and publish pack", "一个模板同时产出文案、海报/图片方向和发布包"), icon: "sparkles", tint: VFStyle.sunset)
                        moduleRow(AppText.localized("Visual templates open directly into AI background and poster editing", "视觉模板可直接进入 AI 背景和海报编辑"), icon: "photo.on.rectangle.angled", tint: VFStyle.purpleFlow)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await appModel.refreshTemplatesIfNeeded()
        }
        .onChange(of: appModel.pendingTemplateWorkflow) { _, workflow in
            guard workflow != nil else { return }
            dismiss()
        }
    }

    private var templateFeedPlacement: AdFeedPlacement? {
        appModel.feedPlacement(for: .templatesList)
    }

    private func shouldInsertFeedAd(after index: Int, total: Int) -> Bool {
        total >= 6 && index == 5
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TemplateCategory.allCases) { category in
                    Button {
                        withAnimation(.snappy) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: categoryIcon(category))
                            Text(category.displayName)
                            Text("\(templateCount(for: category))")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(selectedCategory == category ? VFStyle.ink : .white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(selectedCategory == category ? .white.opacity(0.88) : VFStyle.templateTint(category), in: Capsule())
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectedCategory == category ? .white : VFStyle.ink)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(selectedCategory == category ? VFStyle.templateTint(category) : .white.opacity(0.68))
                        }
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.78), lineWidth: 1)
                        }
                        .shadow(color: VFStyle.templateTint(category).opacity(selectedCategory == category ? 0.22 : 0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func templateCount(for category: TemplateCategory) -> Int {
        appModel.visibleTemplates.filter { $0.category == category }.count
    }

    private func moduleRow(_ text: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VFStyle.ink)
            Spacer()
        }
    }

    private func categoryIcon(_ category: TemplateCategory) -> String {
        switch category {
        case .productSeeding: "shippingbox.fill"
        case .storeTraffic: "mappin.and.ellipse"
        case .personalBrand: "person.crop.square.filled.and.at.rectangle"
        case .liveLaunch: "dot.radiowaves.left.and.right"
        case .seasonalPromo: "gift.fill"
        case .newLaunch: "sparkles.rectangle.stack.fill"
        }
    }
}

private struct TemplateCard: View {
    let template: CreativeTemplate

    private var tint: Color {
        VFStyle.platformTint(template.platform)
    }

    var body: some View {
        VFGlassCard(level: .thin) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    TemplatePosterPreview(template: template)
                    .frame(width: 86, height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .shadow(color: tint.opacity(0.16), radius: 12, x: 0, y: 7)

                    if template.lockedToPro {
                        Image(systemName: "crown.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(VFStyle.sunset)
                            .frame(width: 23, height: 23)
                            .background(.white.opacity(0.90), in: Circle())
                            .offset(x: 5, y: -5)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Text(template.platform.displayName)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tint, in: Capsule())
                        Text(template.category.displayName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(VFStyle.secondaryText)
                    }

                    Text(template.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)
                        .lineLimit(2)

                    Text(template.promptHint)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        ForEach(template.outputBadges.prefix(3), id: \.self) { item in
                            Text(item)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tint.opacity(0.10), in: Capsule())
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VFStyle.secondaryText.opacity(0.55))
            }
        }
    }
}

struct TemplatePosterPreview: View {
    let template: CreativeTemplate
    var isLarge = false

    private var spec: TemplatePosterSpec {
        TemplatePosterSpec(template: template)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scale = max(0.55, min(size.width, size.height) / 360)
            let visual = spec

            ZStack {
                visual.background

                RoundedRectangle(cornerRadius: size.width * 0.08)
                    .fill(.white.opacity(0.16))
                    .rotationEffect(.degrees(-8))
                    .frame(width: size.width * 1.18, height: size.height * 0.34)
                    .offset(y: -size.height * 0.24)

                RoundedRectangle(cornerRadius: size.width * 0.06)
                    .fill(visual.secondary.opacity(0.13))
                    .frame(width: size.width * 0.74, height: size.height * 0.20)
                    .offset(x: size.width * 0.18, y: size.height * 0.20)

                posterScene(size: size, visual: visual)
                    .padding(.horizontal, size.width * 0.08)
                    .padding(.top, size.height * (isLarge ? 0.08 : 0.10))
                    .padding(.bottom, size.height * 0.25)

                VStack(alignment: .leading, spacing: max(4, 8 * scale)) {
                    HStack {
                        Text(template.platform.displayName)
                            .font(.system(size: max(8, 12 * scale), weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .foregroundStyle(visual.ink)
                            .padding(.horizontal, max(7, 10 * scale))
                            .padding(.vertical, max(4, 6 * scale))
                            .background(.white.opacity(0.86), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(.white.opacity(0.88), lineWidth: 1)
                            }
                        Spacer()
                        if isLarge {
                            Image(systemName: visual.icon)
                                .font(.system(size: max(13, 18 * scale), weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: max(28, 38 * scale), height: max(28, 38 * scale))
                                .background(visual.accent, in: Circle())
                                .shadow(color: visual.accent.opacity(0.36), radius: 12, x: 0, y: 6)
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: max(5, 8 * scale)) {
                        Text(visual.headline)
                            .font(.system(size: isLarge ? max(28, 43 * scale) : max(16, 24 * scale), weight: .black, design: .rounded))
                            .lineLimit(isLarge ? 2 : 3)
                            .minimumScaleFactor(0.48)
                            .foregroundStyle(visual.ink)

                        Text(isLarge ? template.name : visual.subtitle)
                            .font(.system(size: isLarge ? max(14, 18 * scale) : max(9, 13 * scale), weight: .bold, design: .rounded))
                            .lineLimit(2)
                            .minimumScaleFactor(0.55)
                            .foregroundStyle(visual.ink.opacity(0.72))

                        if isLarge {
                            HStack(spacing: 7) {
                                posterBadge(visual.badge, tint: visual.accent, scale: scale)
                                posterBadge(template.category.displayName, tint: visual.secondary, scale: scale)
                            }
                        }
                    }
                }
                .padding(size.width * (isLarge ? 0.09 : 0.12))
            }
            .overlay {
                RoundedRectangle(cornerRadius: isLarge ? 28 : 17)
                    .stroke(.white.opacity(0.88), lineWidth: isLarge ? 1.4 : 0.9)
            }
            .clipShape(RoundedRectangle(cornerRadius: isLarge ? 28 : 17))
        }
        .aspectRatio(0.74, contentMode: .fit)
    }

    @ViewBuilder
    private func posterScene(size: CGSize, visual: TemplatePosterSpec) -> some View {
        switch visual.layout {
        case .productHero:
            ProductPosterScene(visual: visual)
        case .videoCover:
            VideoCoverTemplateScene(visual: visual)
        case .comparison:
            ComparisonTemplateScene(visual: visual)
        case .checklist:
            ChecklistTemplateScene(visual: visual)
        case .localVisit:
            StorePosterScene(visual: visual)
        case .profileStory:
            PersonalBrandPosterScene(visual: visual)
        case .liveEvent:
            LiveLaunchPosterScene(visual: visual)
        case .giftGuide:
            SeasonalPosterScene(visual: visual)
        case .launchHero:
            NewLaunchPosterScene(visual: visual)
        case .infoCard:
            InfoCardTemplateScene(visual: visual)
        }
    }

    private func posterBadge(_ text: String, tint: Color, scale: CGFloat) -> some View {
        Text(text)
            .font(.system(size: max(10, 12 * scale), weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.66)
            .foregroundStyle(.white)
            .padding(.horizontal, max(10, 12 * scale))
            .padding(.vertical, max(6, 7 * scale))
            .background(tint, in: Capsule())
            .shadow(color: tint.opacity(0.28), radius: 8, x: 0, y: 4)
    }
}

private struct TemplatePosterSpec {
    let template: CreativeTemplate

    var isChinese: Bool {
        [.xiaohongshu, .douyin, .weChat].contains(template.platform)
    }

    var layout: TemplatePreviewLayout {
        let text = "\(template.name) \(template.promptHint)".lowercased()

        if text.contains("直播") || text.contains("live") || text.contains("预约") || text.contains("倒计时") || text.contains("countdown") {
            return .liveEvent
        }
        if text.contains("节日") || text.contains("礼物") || text.contains("促销") || text.contains("gift") || text.contains("promo") || text.contains("sale") || text.contains("deal") {
            return .giftGuide
        }
        if text.contains("新品") || text.contains("首发") || text.contains("new product") || text.contains("launch") || text.contains("arrival") {
            return .launchHero
        }
        if text.contains("门店") || text.contains("探店") || text.contains("到店") || text.contains("local") || text.contains("visit") || text.contains("route") {
            return .localVisit
        }
        if text.contains("ip") || text.contains("专家") || text.contains("创始人") || text.contains("founder") || text.contains("expert") || text.contains("creator") {
            return .profileStory
        }
        if text.contains("对比") || text.contains("before after") || text.contains("comparison") {
            return .comparison
        }
        if text.contains("清单") || text.contains("checklist") || text.contains("guide") || text.contains("faq") || text.contains("carousel") {
            return .checklist
        }
        if text.contains("首帧") || text.contains("封面") || text.contains("cover") || text.contains("first-frame") || text.contains("shorts") || text.contains("tiktok") || text.contains("douyin") || text.contains("口播") || text.contains("脚本") || text.contains("script") {
            return .videoCover
        }
        if text.contains("成分") || text.contains("解析") || text.contains("ingredient") || text.contains("breakdown") {
            return .infoCard
        }
        return .productHero
    }

    var accent: Color {
        switch template.category {
        case .productSeeding: VFStyle.primaryRed
        case .storeTraffic: VFStyle.electricCyan
        case .personalBrand: VFStyle.purpleFlow
        case .liveLaunch: VFStyle.sunset
        case .seasonalPromo: VFStyle.auroraPink
        case .newLaunch: VFStyle.teal
        }
    }

    var secondary: Color {
        switch template.category {
        case .productSeeding: VFStyle.sunset
        case .storeTraffic: VFStyle.teal
        case .personalBrand: VFStyle.electricCyan
        case .liveLaunch: VFStyle.primaryRed
        case .seasonalPromo: VFStyle.sunset
        case .newLaunch: VFStyle.purpleFlow
        }
    }

    var ink: Color {
        switch template.category {
        case .liveLaunch: .white
        case .newLaunch: Color(red: 0.06, green: 0.14, blue: 0.18)
        default: VFStyle.ink
        }
    }

    var background: LinearGradient {
        switch template.category {
        case .productSeeding:
            LinearGradient(colors: [Color(red: 1.0, green: 0.96, blue: 0.93), Color(red: 1.0, green: 0.80, blue: 0.70), Color(red: 1.0, green: 0.98, blue: 0.90)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .storeTraffic:
            LinearGradient(colors: [Color(red: 0.88, green: 1.0, blue: 0.98), Color(red: 0.68, green: 0.91, blue: 1.0), Color(red: 1.0, green: 0.97, blue: 0.84)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .personalBrand:
            LinearGradient(colors: [Color(red: 0.96, green: 0.93, blue: 1.0), Color(red: 0.83, green: 0.90, blue: 1.0), Color(red: 1.0, green: 0.94, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .liveLaunch:
            LinearGradient(colors: [Color(red: 0.14, green: 0.04, blue: 0.16), Color(red: 0.45, green: 0.06, blue: 0.20), Color(red: 1.0, green: 0.38, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .seasonalPromo:
            LinearGradient(colors: [Color(red: 1.0, green: 0.90, blue: 0.94), Color(red: 1.0, green: 0.74, blue: 0.61), Color(red: 1.0, green: 0.96, blue: 0.78)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .newLaunch:
            LinearGradient(colors: [Color(red: 0.86, green: 1.0, blue: 0.94), Color(red: 0.72, green: 0.93, blue: 1.0), Color(red: 0.98, green: 0.94, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var icon: String {
        switch layout {
        case .productHero: "shippingbox.fill"
        case .videoCover: "play.rectangle.fill"
        case .comparison: "rectangle.split.2x1.fill"
        case .checklist: "checklist"
        case .localVisit: "mappin.and.ellipse"
        case .profileStory: "person.crop.circle.fill"
        case .liveEvent: "dot.radiowaves.left.and.right"
        case .giftGuide: "gift.fill"
        case .launchHero: "sparkles"
        case .infoCard: "text.magnifyingglass"
        }
    }

    var headline: String {
        switch layout {
        case .productHero: isChinese ? "一眼想买" : "Worth Buying"
        case .videoCover: isChinese ? "停留首帧" : "Stop Scroll"
        case .comparison: isChinese ? "对比有结论" : "Clear Comparison"
        case .checklist: isChinese ? "收藏清单" : "Saveable List"
        case .localVisit: isChinese ? "周末就去" : "Go This Weekend"
        case .profileStory: isChinese ? "建立信任" : "Build Trust"
        case .liveEvent: isChinese ? "今晚开抢" : "Live Drop"
        case .giftGuide: isChinese ? "限时好礼" : "Giftable Now"
        case .launchHero: isChinese ? "新品首发" : "New Arrival"
        case .infoCard: isChinese ? "看懂再买" : "Know Why"
        }
    }

    var subtitle: String {
        switch layout {
        case .productHero: isChinese ? "商品主视觉" : "Product hero visual"
        case .videoCover: isChinese ? "短视频封面骨架" : "Short video cover"
        case .comparison: isChinese ? "卖点对比结构" : "Benefit comparison"
        case .checklist: isChinese ? "清单图文结构" : "Checklist layout"
        case .localVisit: isChinese ? "门店打卡场景" : "Local visit hook"
        case .profileStory: isChinese ? "专家信任背书" : "Creator authority"
        case .liveEvent: isChinese ? "直播成交氛围" : "Live commerce drop"
        case .giftGuide: isChinese ? "节日促销氛围" : "Seasonal promo visual"
        case .launchHero: isChinese ? "新品发布主视觉" : "Launch key visual"
        case .infoCard: isChinese ? "信息拆解卡片" : "Explainer card"
        }
    }

    var badge: String {
        switch layout {
        case .productHero: isChinese ? "商品实拍感" : "Product shot"
        case .videoCover: isChinese ? "大字首帧" : "Cover"
        case .comparison: isChinese ? "对比图" : "Compare"
        case .checklist: isChinese ? "可收藏" : "Saveable"
        case .localVisit: isChinese ? "打卡场景" : "Visit hook"
        case .profileStory: isChinese ? "信任背书" : "Authority"
        case .liveEvent: isChinese ? "强转化" : "High intent"
        case .giftGuide: isChinese ? "优惠氛围" : "Promo"
        case .launchHero: isChinese ? "发布感" : "Launch"
        case .infoCard: isChinese ? "信息解释" : "Explainer"
        }
    }
}

private enum TemplatePreviewLayout {
    case productHero
    case videoCover
    case comparison
    case checklist
    case localVisit
    case profileStory
    case liveEvent
    case giftGuide
    case launchHero
    case infoCard
}

private struct ProductPosterScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.07)
                    .fill(.white.opacity(0.55))
                    .frame(width: w * 0.62, height: h * 0.52)
                    .rotationEffect(.degrees(-7))
                    .offset(x: -w * 0.14, y: -h * 0.02)
                    .shadow(color: visual.accent.opacity(0.18), radius: w * 0.06, x: 0, y: w * 0.04)

                RoundedRectangle(cornerRadius: w * 0.10)
                    .fill(LinearGradient(colors: [.white, visual.accent.opacity(0.18)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.23, height: h * 0.50)
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: w * 0.035)
                            .stroke(visual.accent.opacity(0.62), lineWidth: max(1, w * 0.012))
                            .frame(width: w * 0.13, height: h * 0.18)
                    }
                    .offset(x: w * 0.12, y: -h * 0.04)
                    .shadow(color: .black.opacity(0.12), radius: w * 0.07, x: 0, y: w * 0.04)

                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(LinearGradient(colors: [visual.secondary.opacity(0.95), visual.accent.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.28, height: h * 0.18)
                    .rotationEffect(.degrees(11))
                    .offset(x: w * 0.22, y: h * 0.20)

                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? visual.secondary.opacity(0.8) : .white.opacity(0.85))
                        .frame(width: w * 0.035, height: w * 0.035)
                        .offset(x: CGFloat(index - 2) * w * 0.12, y: -h * 0.24 + CGFloat(index % 2) * h * 0.08)
                }
            }
        }
    }
}

private struct VideoCoverTemplateScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.07)
                    .fill(.black.opacity(visual.template.category == .liveLaunch ? 0.26 : 0.12))
                    .frame(width: w * 0.76, height: h * 0.54)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: h * 0.035) {
                            Capsule()
                                .fill(.white.opacity(0.86))
                                .frame(width: w * 0.46, height: h * 0.052)
                            Capsule()
                                .fill(.white.opacity(0.62))
                                .frame(width: w * 0.32, height: h * 0.035)
                        }
                        .padding(w * 0.075)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "play.fill")
                            .font(.system(size: w * 0.16, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: w * 0.26, height: w * 0.26)
                            .background(visual.accent.opacity(0.92), in: Circle())
                            .padding(w * 0.055)
                    }
                    .shadow(color: visual.accent.opacity(0.22), radius: w * 0.07, x: 0, y: w * 0.04)

                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(visual.secondary.opacity(0.84))
                    .frame(width: w * 0.24, height: h * 0.18)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -w * 0.24, y: h * 0.20)
            }
        }
    }
}

private struct ComparisonTemplateScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            HStack(spacing: w * 0.06) {
                comparisonPanel(tint: visual.secondary, icon: "minus")
                comparisonPanel(tint: visual.accent, icon: "checkmark")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .center) {
                Capsule()
                    .fill(.white.opacity(0.94))
                    .frame(width: w * 0.10, height: h * 0.36)
                    .overlay {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: w * 0.055, weight: .black))
                            .foregroundStyle(visual.accent)
                    }
            }
        }
    }

    private func comparisonPanel(tint: Color, icon: String) -> some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            RoundedRectangle(cornerRadius: w * 0.12)
                .fill(.white.opacity(0.72))
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: w * 0.10)
                        .fill(tint.opacity(0.88))
                        .frame(height: h * 0.42)
                        .overlay {
                            Image(systemName: icon)
                                .font(.system(size: w * 0.18, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .padding(w * 0.08)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: h * 0.035) {
                        Capsule().fill(VFStyle.ink.opacity(0.18)).frame(width: w * 0.60, height: h * 0.035)
                        Capsule().fill(VFStyle.ink.opacity(0.12)).frame(width: w * 0.46, height: h * 0.030)
                    }
                    .padding(w * 0.10)
                }
        }
    }
}

private struct ChecklistTemplateScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            RoundedRectangle(cornerRadius: w * 0.08)
                .fill(.white.opacity(0.76))
                .frame(width: w * 0.78, height: h * 0.56)
                .overlay {
                    VStack(alignment: .leading, spacing: h * 0.06) {
                        ForEach(0..<4, id: \.self) { index in
                            HStack(spacing: w * 0.04) {
                                Image(systemName: index == 0 ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: w * 0.075, weight: .bold))
                                    .foregroundStyle(index == 0 ? visual.accent : visual.secondary.opacity(0.52))
                                Capsule()
                                    .fill(index == 0 ? visual.accent.opacity(0.52) : VFStyle.ink.opacity(0.12))
                                    .frame(width: w * (0.42 - CGFloat(index % 2) * 0.08), height: h * 0.032)
                            }
                        }
                    }
                    .padding(w * 0.11)
                }
                .shadow(color: visual.accent.opacity(0.18), radius: w * 0.07, x: 0, y: w * 0.04)
        }
    }
}

private struct StorePosterScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(.white.opacity(0.78))
                    .frame(width: w * 0.78, height: h * 0.48)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: w * 0.04)
                            .fill(LinearGradient(colors: [visual.accent, visual.secondary], startPoint: .leading, endPoint: .trailing))
                            .frame(height: h * 0.13)
                            .overlay {
                                Text(visual.isChinese ? "今日打卡" : "LOCAL PICK")
                                    .font(.system(size: max(8, w * 0.07), weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                    }
                    .overlay(alignment: .bottom) {
                        HStack(spacing: w * 0.04) {
                            RoundedRectangle(cornerRadius: w * 0.03)
                                .fill(visual.secondary.opacity(0.28))
                            RoundedRectangle(cornerRadius: w * 0.03)
                                .fill(visual.accent.opacity(0.22))
                            RoundedRectangle(cornerRadius: w * 0.03)
                                .fill(visual.secondary.opacity(0.28))
                        }
                        .frame(height: h * 0.18)
                        .padding(w * 0.07)
                    }
                    .shadow(color: visual.accent.opacity(0.22), radius: w * 0.07, x: 0, y: w * 0.04)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: w * 0.28, weight: .black))
                    .foregroundStyle(.white, visual.accent)
                    .offset(x: w * 0.25, y: -h * 0.20)
                    .shadow(color: visual.accent.opacity(0.32), radius: w * 0.06, x: 0, y: w * 0.03)
            }
        }
    }
}

private struct PersonalBrandPosterScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.08)
                    .fill(.white.opacity(0.70))
                    .frame(width: w * 0.72, height: h * 0.54)
                    .rotationEffect(.degrees(5))
                    .shadow(color: visual.accent.opacity(0.18), radius: w * 0.08, x: 0, y: w * 0.05)

                Circle()
                    .fill(LinearGradient(colors: [visual.accent.opacity(0.92), visual.secondary.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.32, height: w * 0.32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: w * 0.17, weight: .black))
                            .foregroundStyle(.white.opacity(0.94))
                    }
                    .offset(x: -w * 0.18, y: -h * 0.11)

                VStack(alignment: .leading, spacing: h * 0.04) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == 0 ? visual.accent.opacity(0.64) : VFStyle.ink.opacity(0.13))
                            .frame(width: w * (index == 0 ? 0.36 : 0.48), height: h * 0.035)
                    }
                }
                .offset(x: w * 0.12, y: h * 0.10)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: w * 0.16, weight: .black))
                    .foregroundStyle(.white, visual.secondary)
                    .offset(x: w * 0.24, y: -h * 0.15)
            }
        }
    }
}

private struct InfoCardTemplateScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.08)
                    .fill(.white.opacity(0.78))
                    .frame(width: w * 0.78, height: h * 0.56)
                    .overlay(alignment: .topLeading) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: w * 0.14, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: w * 0.24, height: w * 0.24)
                            .background(visual.accent, in: Circle())
                            .padding(w * 0.08)
                    }
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: h * 0.035) {
                            Capsule().fill(visual.accent.opacity(0.44)).frame(width: w * 0.42, height: h * 0.04)
                            Capsule().fill(VFStyle.ink.opacity(0.13)).frame(width: w * 0.58, height: h * 0.03)
                            Capsule().fill(VFStyle.ink.opacity(0.10)).frame(width: w * 0.46, height: h * 0.03)
                        }
                        .padding(w * 0.10)
                    }
                    .shadow(color: visual.accent.opacity(0.18), radius: w * 0.07, x: 0, y: w * 0.04)

                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(visual.secondary.opacity(0.82))
                    .frame(width: w * 0.28, height: h * 0.16)
                    .rotationEffect(.degrees(8))
                    .offset(x: w * 0.24, y: -h * 0.20)
            }
        }
    }
}

private struct LiveLaunchPosterScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(index.isMultiple(of: 2) ? visual.secondary.opacity(0.45) : .white.opacity(0.28))
                        .frame(width: w * 0.025, height: h * 0.45)
                        .rotationEffect(.degrees(Double(index) * 22 - 78))
                        .offset(y: -h * 0.10)
                }

                RoundedRectangle(cornerRadius: w * 0.07)
                    .fill(LinearGradient(colors: [visual.secondary, visual.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.70, height: h * 0.42)
                    .overlay {
                        VStack(spacing: h * 0.04) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: w * 0.22, weight: .black))
                            Capsule()
                                .fill(.white.opacity(0.86))
                                .frame(width: w * 0.36, height: h * 0.035)
                            Capsule()
                                .fill(.white.opacity(0.62))
                                .frame(width: w * 0.50, height: h * 0.030)
                        }
                        .foregroundStyle(.white)
                    }
                    .shadow(color: visual.secondary.opacity(0.34), radius: w * 0.08, x: 0, y: w * 0.05)

                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(.white.opacity(0.90))
                    .frame(width: w * 0.30, height: h * 0.14)
                    .overlay {
                        Image(systemName: "tag.fill")
                            .font(.system(size: w * 0.12, weight: .black))
                            .foregroundStyle(visual.accent)
                    }
                    .rotationEffect(.degrees(-9))
                    .offset(x: w * 0.24, y: h * 0.21)
            }
        }
    }
}

private struct SeasonalPosterScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(visual.secondary.opacity(0.88))
                    .frame(width: w * 0.46, height: h * 0.35)
                    .overlay {
                        Rectangle()
                            .fill(.white.opacity(0.65))
                            .frame(width: w * 0.08)
                    }
                    .offset(x: -w * 0.14, y: h * 0.04)
                    .shadow(color: visual.accent.opacity(0.20), radius: w * 0.08, x: 0, y: w * 0.05)

                RoundedRectangle(cornerRadius: w * 0.05)
                    .fill(visual.accent.opacity(0.92))
                    .frame(width: w * 0.32, height: h * 0.25)
                    .overlay {
                        Rectangle()
                            .fill(.white.opacity(0.55))
                            .frame(width: w * 0.06)
                    }
                    .rotationEffect(.degrees(8))
                    .offset(x: w * 0.20, y: h * 0.12)

                Image(systemName: "sparkles")
                    .font(.system(size: w * 0.25, weight: .black))
                    .foregroundStyle(.white.opacity(0.95))
                    .offset(x: w * 0.12, y: -h * 0.20)
            }
        }
    }
}

private struct NewLaunchPosterScene: View {
    let visual: TemplatePosterSpec

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Ellipse()
                    .fill(.white.opacity(0.70))
                    .frame(width: w * 0.72, height: h * 0.18)
                    .offset(y: h * 0.22)

                RoundedRectangle(cornerRadius: w * 0.08)
                    .fill(LinearGradient(colors: [.white, visual.accent.opacity(0.28)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.34, height: h * 0.44)
                    .rotationEffect(.degrees(-7))
                    .offset(x: -w * 0.12, y: -h * 0.02)
                    .shadow(color: visual.secondary.opacity(0.24), radius: w * 0.08, x: 0, y: w * 0.05)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: w * 0.26, weight: .black))
                    .foregroundStyle(visual.secondary)
                    .offset(x: w * 0.20, y: -h * 0.04)

                Image(systemName: "sparkle")
                    .font(.system(size: w * 0.15, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: w * 0.25, height: w * 0.25)
                    .background(visual.secondary, in: Capsule())
                    .rotationEffect(.degrees(9))
                    .offset(x: w * 0.20, y: -h * 0.24)
            }
        }
    }
}

struct TemplateDetailView: View {
    @Environment(AppModel.self) private var appModel
    let template: CreativeTemplate

    @State private var draft: GenerationDraft
    @State private var generatedProject: ContentProject?

    private var canGenerate: Bool {
        !appModel.isGenerating && draft.isReadyToGenerate
    }

    private var requiresPro: Bool {
        template.lockedToPro && !appModel.quota.isPro
    }

    private var visibleTopicValidationMessage: String? {
        draft.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.topicValidationMessage
    }

    init(template: CreativeTemplate) {
        self.template = template
        _draft = State(initialValue: GenerationDraft(platform: template.platform, goal: template.category.defaultGoal, audience: template.defaultAudience, tone: template.defaultTone, templateName: template.name, templatePromptHint: template.promptHint, templateStyle: template.style))
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Template", "模板"),
                subtitle: template.name,
                icon: "rectangle.on.rectangle.fill",
                tint: VFStyle.platformTint(template.platform)
            )

            TemplatePosterPreview(template: template, isLarge: true)
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: VFStyle.platformTint(template.platform).opacity(0.14), radius: 20, x: 0, y: 12)

            VFGlassCard(level: .thick) {
                VStack(alignment: .leading, spacing: 15) {
                    Label(template.lockedToPro ? AppText.localized("Pro template", "会员模板") : AppText.localized("Free template", "免费模板"), systemImage: template.lockedToPro ? "crown.fill" : "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(template.lockedToPro ? VFStyle.sunset : VFStyle.teal)

                    Text(template.name)
                        .font(.title3.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                    Text(template.promptHint)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)

                    VStack(spacing: 12) {
                        detailInfoRow(
                            title: AppText.localized("Best for", "适合人群"),
                            value: template.defaultAudience,
                            icon: "person.2.fill",
                            tint: VFStyle.electricCyan
                        )
                        detailInfoRow(
                            title: AppText.localized("Tone", "语气"),
                            value: template.defaultTone,
                            icon: "quote.bubble.fill",
                            tint: VFStyle.sunset
                        )
                    }

                    structureCard

                    if requiresPro {
                        proLockedCard
                    }

                    VStack(spacing: 12) {
                        glassTextField(AppText.localized("Topic or product", "主题或产品"), text: $draft.topic, lines: 3)
                        glassTextField(AppText.localized("Audience", "目标人群"), text: $draft.audience, lines: 1)
                        glassTextField(AppText.localized("Tone", "语气风格"), text: $draft.tone, lines: 1)
                    }

                    if appModel.brandProfile.hasSavedMemory {
                        Label(appModel.brandProfile.memorySummary, systemImage: "brain")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(VFStyle.secondaryText)
                    }
                    if let message = visibleTopicValidationMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(VFStyle.warning)
                    }

                    Button {
                        guard !requiresPro else {
                            openTemplatePaywall()
                            return
                        }
                        appModel.applyTemplateToStudio(template, draft: draft)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.pencil")
                                .font(.headline.weight(.bold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppText.localized("Apply to Studio", "套用到创作台"))
                                    .font(.headline.weight(.bold))
                                Text(AppText.localized("Fill the product brief on the Create page", "回到创作页补产品主题"))
                                    .font(.caption.weight(.semibold))
                                    .opacity(0.78)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3.weight(.bold))
                        }
                        .foregroundStyle(VFStyle.ink)
                        .padding(15)
                        .background(.white.opacity(0.66), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.86), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.templateDetail.applyToStudioButton")

                    VFPrimaryButton(
                        title: templateActionTitle,
                        icon: requiresPro ? "crown.fill" : "wand.and.stars",
                        isLoading: appModel.isGenerating,
                        isEnabled: requiresPro || canGenerate
                    ) {
                        generate()
                    }
                    .accessibilityIdentifier("vf.templateDetail.useTemplateButton")

                    if let generationError = appModel.generationError {
                        templateErrorCard(generationError)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $generatedProject) { project in
            ResultView(project: project)
        }
        .onChange(of: draft) { _, _ in
            appModel.generationError = nil
        }
    }

    private var structureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VFSectionHeader(
                title: AppText.localized("Output Structure", "内容结构"),
                subtitle: template.sampleOutcome
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(template.contentStructure.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(VFStyle.templateTint(template.category), in: Circle())
                        Text(item)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(VFStyle.ink)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(.white.opacity(0.60), in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.84), lineWidth: 1)
                    }
                }
            }
        }
        .padding(14)
        .background(VFStyle.templateTint(template.category).opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.70), lineWidth: 1)
        }
    }

    private var proLockedCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VFGradientIcon(icon: "crown.fill", tint: VFStyle.sunset, size: 36)
            VStack(alignment: .leading, spacing: 5) {
                Text(AppText.localized("Pro workflow", "会员专属工作流"))
                    .font(.headline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                Text(AppText.localized(
                    "This template is built for higher-value campaigns and unlocks with ViralForge Pro.",
                    "该模板面向更高价值的活动场景，开通 ViralForge Pro 后可使用。"
                ))
                .font(.caption.weight(.semibold))
                .foregroundStyle(VFStyle.secondaryText)
            }
        }
        .padding(14)
        .background(VFStyle.sunset.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(VFStyle.sunset.opacity(0.22), lineWidth: 1)
        }
        .accessibilityIdentifier("vf.templateDetail.proLockedCard")
    }

    private var templateActionTitle: String {
        if requiresPro {
            return AppText.localized("Upgrade to Use Template", "升级后使用模板")
        }

        if appModel.isGenerating {
            return AppText.localized("Generating...", "生成中...")
        }

        return AppText.localized("Use Template", "使用模板")
    }

    private func detailInfoRow(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 11) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VFStyle.secondaryText)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VFStyle.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.82), lineWidth: 1)
        }
    }

    private func glassTextField(_ placeholder: String, text: Binding<String>, lines: Int) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(lines, reservesSpace: true)
            .font(.subheadline.weight(.semibold))
            .padding(13)
            .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.82), lineWidth: 1)
            }
    }

    private func generate() {
        guard !requiresPro else {
            openTemplatePaywall()
            return
        }

        Task {
            var templateDraft = appModel.draft(from: template)
            templateDraft.topic = draft.topic
            templateDraft.audience = draft.audience
            templateDraft.tone = draft.tone
            generatedProject = await appModel.generateProject(from: templateDraft)
        }
    }

    private func openTemplatePaywall() {
        appModel.openPaywall(reason: AppText.localized(
            "This is a Pro template. Upgrade to unlock premium templates, AI background generation, and watermark-free exports.",
            "这是会员模板。升级后可解锁会员模板、AI 背景生成和无水印导出。"
        ))
    }

    private func templateErrorCard(_ message: String) -> some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(VFStyle.warning)

                HStack(spacing: 12) {
                    Button {
                        generate()
                    } label: {
                        Label(AppText.localized("Retry", "重试"), systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(VFStyle.accent)
                    }
                    .disabled(!canGenerate)
                    .accessibilityIdentifier("vf.templateDetail.generationError.retryButton")

                    if appModel.showTextGenerationRewardError {
                        Button {
                            Task {
                                if await appModel.requestTextGenerationReward() {
                                    appModel.generationError = nil
                                    generate()
                                }
                            }
                        } label: {
                            Label(AppText.localized("Watch Ad", "看广告"), systemImage: "play.rectangle.on.rectangle")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.09, green: 0.16, blue: 0.34), VFStyle.primaryRed],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                                .shadow(color: Color(red: 0.1, green: 0.16, blue: 0.34).opacity(0.28), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                        .disabled(appModel.isRequestingTextGenerationReward)
                        .accessibilityLabel(AppText.localized("Watch Ad", "看广告"))
                        .accessibilityIdentifier("vf.templateDetail.generationError.watchAdButton")
                    } else if !appModel.quota.isPro {
                        Button {
                            appModel.generationError = nil
                            appModel.openPaywall(reason: message)
                        } label: {
                            Label(AppText.localized("Upgrade Pro", "升级 Pro"), systemImage: "crown.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    LinearGradient(colors: [VFStyle.primaryRed, VFStyle.sunset], startPoint: .leading, endPoint: .trailing),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppText.localized("Upgrade Pro", "升级 Pro"))
                        .accessibilityIdentifier("vf.templateDetail.generationError.upgradeButton")
                    }
                }
            }
        }
        .accessibilityIdentifier("vf.templateDetail.generationError")
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
            .environment(AppModel())
    }
}
