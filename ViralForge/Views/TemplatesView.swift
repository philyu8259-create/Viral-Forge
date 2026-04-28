import SwiftUI

struct TemplatesView: View {
    @Environment(AppModel.self) private var appModel
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
                    ForEach(filteredTemplates) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("vf.templateCard.\(template.name)")
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

private struct TemplatePosterPreview: View {
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

                Circle()
                    .fill(visual.accent.opacity(0.30))
                    .frame(width: size.width * 0.92, height: size.width * 0.92)
                    .blur(radius: size.width * 0.14)
                    .offset(x: -size.width * 0.34, y: -size.height * 0.34)

                Circle()
                    .fill(visual.secondary.opacity(0.30))
                    .frame(width: size.width * 0.76, height: size.width * 0.76)
                    .blur(radius: size.width * 0.15)
                    .offset(x: size.width * 0.34, y: -size.height * 0.08)

                Rectangle()
                    .fill(.white.opacity(0.08))
                    .rotationEffect(.degrees(-11))
                    .frame(width: size.width * 1.4, height: size.height * 0.42)
                    .offset(y: -size.height * 0.18)

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
        switch template.category {
        case .productSeeding:
            ProductPosterScene(visual: visual)
        case .storeTraffic:
            StorePosterScene(visual: visual)
        case .personalBrand:
            PersonalBrandPosterScene(visual: visual)
        case .liveLaunch:
            LiveLaunchPosterScene(visual: visual)
        case .seasonalPromo:
            SeasonalPosterScene(visual: visual)
        case .newLaunch:
            NewLaunchPosterScene(visual: visual)
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
        switch template.category {
        case .productSeeding: "shippingbox.fill"
        case .storeTraffic: "mappin.and.ellipse"
        case .personalBrand: "person.crop.circle.fill"
        case .liveLaunch: "dot.radiowaves.left.and.right"
        case .seasonalPromo: "gift.fill"
        case .newLaunch: "sparkles"
        }
    }

    var headline: String {
        switch template.category {
        case .productSeeding: isChinese ? "一眼想买" : "Worth Buying"
        case .storeTraffic: isChinese ? "周末就去" : "Go This Weekend"
        case .personalBrand: isChinese ? "建立信任" : "Build Trust"
        case .liveLaunch: isChinese ? "今晚开抢" : "Live Drop"
        case .seasonalPromo: isChinese ? "限时好礼" : "Giftable Now"
        case .newLaunch: isChinese ? "新品首发" : "New Arrival"
        }
    }

    var subtitle: String {
        switch template.category {
        case .productSeeding: isChinese ? "真实商品示例" : "Product hero sample"
        case .storeTraffic: isChinese ? "门店场景示例" : "Local scene sample"
        case .personalBrand: isChinese ? "专家人设示例" : "Creator authority sample"
        case .liveLaunch: isChinese ? "直播爆点示例" : "Live commerce sample"
        case .seasonalPromo: isChinese ? "节日促销示例" : "Seasonal promo sample"
        case .newLaunch: isChinese ? "新品主视觉示例" : "Launch visual sample"
        }
    }

    var badge: String {
        switch template.category {
        case .productSeeding: isChinese ? "商品实拍感" : "Product shot"
        case .storeTraffic: isChinese ? "打卡场景" : "Visit hook"
        case .personalBrand: isChinese ? "信任背书" : "Authority"
        case .liveLaunch: isChinese ? "强转化" : "High intent"
        case .seasonalPromo: isChinese ? "优惠氛围" : "Promo"
        case .newLaunch: isChinese ? "发布感" : "Launch"
        }
    }
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
                        Capsule()
                            .fill(visual.accent.opacity(0.92))
                            .frame(width: w * 0.15, height: h * 0.11)
                            .overlay {
                                Text("VF")
                                    .font(.system(size: max(7, w * 0.06), weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            }
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
                        VStack(spacing: h * 0.02) {
                            Text(visual.isChinese ? "LIVE" : "LIVE")
                                .font(.system(size: max(16, w * 0.18), weight: .black, design: .rounded))
                            Text(visual.isChinese ? "爆品福利" : "DROP DEAL")
                                .font(.system(size: max(8, w * 0.08), weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                    }
                    .shadow(color: visual.secondary.opacity(0.34), radius: w * 0.08, x: 0, y: w * 0.05)

                RoundedRectangle(cornerRadius: w * 0.04)
                    .fill(.white.opacity(0.90))
                    .frame(width: w * 0.30, height: h * 0.14)
                    .overlay {
                        Text("¥99")
                            .font(.system(size: max(12, w * 0.12), weight: .black, design: .rounded))
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

                Text("NEW")
                    .font(.system(size: max(13, w * 0.15), weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, w * 0.06)
                    .padding(.vertical, h * 0.025)
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
                        title: appModel.isGenerating ? AppText.localized("Generating...", "生成中...") : AppText.localized("Use Template", "使用模板"),
                        icon: "wand.and.stars",
                        isLoading: appModel.isGenerating,
                        isEnabled: canGenerate
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
        Task {
            var templateDraft = appModel.draft(from: template)
            templateDraft.topic = draft.topic
            templateDraft.audience = draft.audience
            templateDraft.tone = draft.tone
            generatedProject = await appModel.generateProject(from: templateDraft)
        }
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

                    if !appModel.quota.isPro {
                        Button {
                            appModel.generationError = nil
                            appModel.selectedTab = .pro
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
