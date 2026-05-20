import SwiftUI
import Photos
import UIKit

private enum PosterExportMode: Hashable {
    case watermarked
    case clean
}

struct PosterEditorView: View {
    @Environment(AppModel.self) private var appModel
    let project: ContentProject

    @State private var poster: PosterDraft
    @State private var exportedUIImage: UIImage?
    @State private var exportedImageURL: URL?
    @State private var exportStatusMessage: String?
    @State private var backgroundStatusMessage: String?
    @State private var isSavingToPhotos = false
    @State private var isGeneratingDirectionPreviews = false
    @State private var isRenderingExport = false
    @State private var showsDirectionPreviewCostAlert = false
    @State private var selectedTarget: PosterCanvasTarget
    @State private var exportMode: PosterExportMode = .watermarked
    @State private var showAdvancedSettings = false
    @State private var selectedTitleID: UUID?
    @State private var selectedHookID: UUID?

    init(project: ContentProject) {
        self.project = project
        _poster = State(initialValue: project.poster)
        _selectedTarget = State(initialValue: PosterCanvasTarget.defaultTarget(for: project.draft.platform))
        _selectedTitleID = State(initialValue: project.result.titles.first?.id)
        _selectedHookID = State(initialValue: project.result.hooks.first?.id)
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Poster", "海报"),
                subtitle: AppText.localized("Edit, render, and export visual assets", "编辑、生成并导出视觉资产"),
                icon: "photo.on.rectangle.angled",
                tint: VFStyle.platformTint(project.draft.platform)
            )

            VStack(spacing: 18) {
                posterWorkflowGuide
                generatedCopyCandidates
                backgroundGenerationControls

                PosterPreview(
                    poster: poster,
                    platform: project.draft.platform,
                    target: selectedTarget,
                    showsWatermark: showsWatermarkForExport
                )
                    .frame(height: 520)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: VFStyle.platformTint(project.draft.platform).opacity(0.16), radius: 22, x: 0, y: 12)
                    .accessibilityIdentifier("vf.poster.preview")

                if poster.productImageData != nil {
                    productImageLockNotice
                }

                posterCopyControls
                posterTextLayerControls
                exportOptions

                QuotaStatusView(quota: appModel.quota, compact: true)

                VFPrimaryButton(
                    title: isRenderingExport
                        ? AppText.localized("Rendering Final Poster...", "正在渲染最终海报...")
                        : showsWatermarkForExport
                        ? AppText.localized("Render Final Branded Poster", "生成最终带标识海报")
                        : AppText.localized("Render Final No-Watermark Poster", "生成最终无水印海报"),
                    icon: "square.and.arrow.down",
                    isLoading: isRenderingExport,
                    isEnabled: !isRenderingExport
                ) {
                    exportPoster()
                }
                .accessibilityIdentifier("vf.poster.renderButton")

                if let exportedImageURL {
                    VFGlassCard {
                        VStack(spacing: 12) {
                            exportResultHeader

                            HStack(spacing: 10) {
                                ShareLink(item: exportedImageURL) {
                                    exportActionLabel(AppText.localized("Share PNG", "分享 PNG 图片"), icon: "square.and.arrow.up", tint: VFStyle.primaryRed)
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)

                                Button {
                                    saveToPhotoLibrary()
                                } label: {
                                    exportActionLabel(
                                        isSavingToPhotos ? AppText.localized("Saving...", "保存中...") : AppText.localized("Save to Photos", "保存到相册"),
                                        icon: "photo.badge.arrow.down",
                                        tint: VFStyle.ink
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isSavingToPhotos || exportedUIImage == nil)
                                .frame(maxWidth: .infinity)
                            }

                            Button {
                                requestCleanExport()
                            } label: {
                                exportActionLabel(
                                    appModel.quota.isPro
                                        ? AppText.localized("Render No-Watermark Copy", "重新生成无水印版")
                                        : AppText.localized("Unlock No-Watermark Export", "解锁无水印导出"),
                                    icon: appModel.quota.isPro ? "checkmark.seal.fill" : "crown.fill",
                                    tint: appModel.quota.isPro ? VFStyle.teal : VFStyle.sunset
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isRenderingExport)
                            .accessibilityIdentifier("vf.poster.noWatermarkButton")
                        }
                    }
                }

                advancedPosterSettings

                if let exportStatusMessage {
                    Label(exportStatusMessage, systemImage: "checkmark.circle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VFStyle.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("vf.poster.exportStatus")
                }

                if let exportedUIImage {
                    VFGlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(AppText.localized("Export Preview", "导出预览"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(VFStyle.ink)
                            Image(uiImage: exportedUIImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(.white.opacity(0.8), lineWidth: 1)
                                }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("vf.poster.screen")
        .alert(AppText.localized("Generate direction previews?", "生成方向预览？"), isPresented: $showsDirectionPreviewCostAlert) {
            Button(AppText.localized("Cancel", "取消"), role: .cancel) {}
            Button(AppText.localized("Generate", "生成")) {
                runDirectionPreviews(generationLimit: directionPreviewGenerationLimit)
            }
        } message: {
            Text(AppText.localized(
                "This will use \(directionPreviewGenerationLimit) AI background credits.",
                "这将消耗 \(directionPreviewGenerationLimit) 次 AI 背景额度。"
            ))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink {
                ResultView(project: project)
            } label: {
                Label(AppText.localized("Content", "文案"), systemImage: "doc.text")
            }
        }
        .onAppear {
            if appModel.quota.isPro {
                exportMode = .clean
            }
        }
    }

    private var posterCopyControls: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Poster Copy", "海报文案"),
                    subtitle: AppText.localized("Editable text layer for headline, subtitle, and CTA; adjust placement in Advanced settings.", "可编辑文字层：先完成标题、文案与 CTA，可在高级设置里调文案位置。")
                )

                posterField(
                    AppText.localized("Headline", "主标题"),
                    text: posterHeadlineBinding,
                    icon: "textformat.size",
                    tint: VFStyle.primaryRed,
                    lines: 2,
                    accessibilityIdentifier: "vf.poster.headlineField"
                )
                posterField(
                    AppText.localized("Subtitle", "副标题"),
                    text: posterSubtitleBinding,
                    icon: "text.alignleft",
                    tint: VFStyle.electricCyan,
                    accessibilityIdentifier: "vf.poster.subtitleField"
                )
                posterField(
                    AppText.localized("CTA", "行动按钮"),
                    text: posterCtaBinding,
                    icon: "hand.tap.fill",
                    tint: VFStyle.sunset,
                    accessibilityIdentifier: "vf.poster.ctaField"
                )
                posterField(
                    AppText.localized("Poster label", "海报标签"),
                    text: posterChannelLabelBinding,
                    icon: "tag.fill",
                    tint: VFStyle.teal,
                    accessibilityIdentifier: "vf.poster.channelLabelField"
                )
            }
        }
    }

    private var posterTextLayerControls: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Text Layer", "文字层样式"),
                    subtitle: AppText.localized("Tune font, size, color, alignment, and fine position.", "调节字体、字号、颜色、对齐和微调位置。")
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.localized("Font", "字体"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)
                    Picker(AppText.localized("Font Family", "字体"), selection: posterTextFontFamilyBinding) {
                        ForEach(PosterTextFontFamily.allCases) { preset in
                            Label(preset.displayName, systemImage: preset.icon).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("vf.poster.textFontFamily")
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.localized("Weight", "字重"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(VFStyle.secondaryText)
                        Picker(AppText.localized("Weight", "字重"), selection: posterTextWeightBinding) {
                            ForEach(PosterTextWeight.allCases) { preset in
                                Text(preset.displayName).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("vf.poster.textWeight")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.localized("Alignment", "对齐"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(VFStyle.secondaryText)
                        Picker(AppText.localized("Alignment", "对齐"), selection: posterTextAlignmentBinding) {
                            ForEach(PosterTextAlignment.allCases) { preset in
                                Label(preset.displayName, systemImage: preset.icon).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("vf.poster.textAlignment")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.localized("Text color", "文字颜色"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)
                    Picker(AppText.localized("Color", "颜色"), selection: posterTextColorBinding) {
                        ForEach(PosterTextColor.allCases) { preset in
                            Label(preset.displayName, systemImage: preset.icon).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("vf.poster.textColor")
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.localized("Headline size", "标题字号"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(VFStyle.secondaryText)
                        Slider(
                            value: posterHeadlineScaleBinding,
                            in: 0.70...1.60,
                            step: 0.05
                        )
                        HStack {
                            Text("0.70")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(VFStyle.secondaryText)
                            Spacer(minLength: 0)
                            Text(AppText.localized(
                                String(format: "Scale %.2fx", poster.clampedHeadlineScale),
                                String(format: "比例 %.2f 倍", poster.clampedHeadlineScale)
                            ))
                            .font(.caption.weight(.black))
                            .foregroundStyle(VFStyle.ink)
                            Spacer(minLength: 0)
                            Text("1.60")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(VFStyle.secondaryText)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.localized("Subtitle size", "副标题字号"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(VFStyle.secondaryText)
                        Slider(
                            value: posterSubtitleScaleBinding,
                            in: 0.70...1.60,
                            step: 0.05
                        )
                        HStack {
                            Text("0.70")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(VFStyle.secondaryText)
                            Spacer(minLength: 0)
                            Text(AppText.localized(
                                String(format: "Scale %.2fx", poster.clampedSubtitleScale),
                                String(format: "比例 %.2f 倍", poster.clampedSubtitleScale)
                            ))
                            .font(.caption.weight(.black))
                            .foregroundStyle(VFStyle.ink)
                            Spacer(minLength: 0)
                            Text("1.60")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(VFStyle.secondaryText)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.localized("CTA size", "按钮字号"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)
                    Slider(value: posterCtaScaleBinding, in: 0.70...1.60, step: 0.05)
                    HStack {
                        Text("0.70")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)
                        Spacer(minLength: 0)
                        Text(AppText.localized(
                            String(format: "Scale %.2fx", poster.clampedCtaScale),
                            String(format: "比例 %.2f 倍", poster.clampedCtaScale)
                        ))
                        .font(.caption.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                        Spacer(minLength: 0)
                        Text("1.60")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.localized("Fine position", "微调位置"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)

                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text(AppText.localized("X", "横向"))
                                .font(.caption.weight(.black))
                                .foregroundStyle(VFStyle.secondaryText)
                                .frame(width: 34, alignment: .leading)
                            Slider(value: posterCopyOffsetXBinding, in: -80...80, step: 1)
                            Text(String(format: "%.0f", poster.clampedCopyOffsetX))
                                .font(.caption2.weight(.black))
                                .frame(width: 34, alignment: .trailing)
                        }
                        HStack(spacing: 12) {
                            Text(AppText.localized("Y", "纵向"))
                                .font(.caption.weight(.black))
                                .foregroundStyle(VFStyle.secondaryText)
                                .frame(width: 34, alignment: .leading)
                            Slider(value: posterCopyOffsetYBinding, in: -80...80, step: 1)
                            Text(String(format: "%.0f", poster.clampedCopyOffsetY))
                                .font(.caption2.weight(.black))
                                .frame(width: 34, alignment: .trailing)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Spacer(minLength: 0)
                    Button {
                        resetTextLayerSettings()
                    } label: {
                        Label(
                            AppText.localized("Reset Recommended Layout", "恢复默认布局"),
                            systemImage: "arrow.counterclockwise"
                        )
                        .font(.caption.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.62), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.78), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.poster.resetTextLayer")
                }
            }
        }
    }

    private var generatedCopyCandidates: some View {
        VFGlassCard(level: .thin) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(AppText.localized("Generated copy is ready", "文案候选已生成"), systemImage: "doc.text.magnifyingglass")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(VFStyle.ink)

                        Text(AppText.localized(
                            "Choose a title or hook to place it on the poster. You can still edit every line below.",
                            "点选标题或钩子即可替换到海报上，下面仍可继续编辑。"
                        ))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                    }

                    Spacer(minLength: 10)

                    NavigationLink {
                        ResultView(project: project)
                    } label: {
                        Label(AppText.localized("All copy", "全部文案"), systemImage: "list.bullet.clipboard")
                            .font(.caption.weight(.black))
                            .labelStyle(.iconOnly)
                            .foregroundStyle(VFStyle.primaryRed)
                            .frame(width: 34, height: 34)
                            .background(VFStyle.primaryRed.opacity(0.10), in: Circle())
                            .accessibilityLabel(AppText.localized("View all generated copy", "查看全部生成文案"))
                    }
                    .buttonStyle(.plain)
                }

                copyCandidateGroup(
                    title: AppText.localized("Title options", "标题候选"),
                    lines: Array(project.result.titles.prefix(3)),
                    selectedID: selectedTitleID,
                    tint: VFStyle.primaryRed,
                    action: applyTitleCandidate
                )

                copyCandidateGroup(
                    title: AppText.localized("Hook options", "开头钩子"),
                    lines: Array(project.result.hooks.prefix(3)),
                    selectedID: selectedHookID,
                    tint: VFStyle.electricCyan,
                    action: applyHookCandidate
                )
            }
        }
        .accessibilityIdentifier("vf.poster.copyCandidates")
    }

    @ViewBuilder
    private func copyCandidateGroup(
        title: String,
        lines: [ScoredLine],
        selectedID: UUID?,
        tint: Color,
        action: @escaping (ScoredLine) -> Void
    ) -> some View {
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(VFStyle.secondaryText)

                VStack(spacing: 7) {
                    ForEach(lines) { line in
                        CopyCandidateButton(
                            line: line,
                            isSelected: selectedID == line.id,
                            tint: tint
                        ) {
                            action(line)
                        }
                    }
                }
            }
        }
    }

    private var posterWorkflowGuide: some View {
        VFGlassCard(level: .thin) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: "rectangle.3.group")
                        .foregroundStyle(VFStyle.primaryRed)
                    Text(AppText.localized("Poster workflow", "海报流程"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.ink)
                }

                HStack(spacing: 7) {
                    workflowStep(
                        number: 1,
                        title: AppText.localized("AI Background", "AI 背景"),
                        subtitle: AppText.localized("Generate a photo layer first.", "先生成背景层。"),
                        isCompleted: hasGeneratedBackground,
                        isActive: workflowActiveStep == 1,
                        icon: "sparkles.rectangle.stack.fill",
                        identifier: "vf.poster.workflowGuide.step1"
                    )

                    workflowConnector

                    workflowStep(
                        number: 2,
                        title: AppText.localized("Poster Copy", "海报文案"),
                        subtitle: AppText.localized("Adjust text and placement.", "再调整文字和位置。"),
                        isCompleted: !poster.headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        isActive: workflowActiveStep == 2,
                        icon: "text.justify",
                        identifier: "vf.poster.workflowGuide.step2"
                    )

                    workflowConnector

                    workflowStep(
                        number: 3,
                        title: AppText.localized("Render & Export", "渲染与导出"),
                        subtitle: AppText.localized("Create final poster file.", "生成最终海报文件。"),
                        isCompleted: hasRenderedPoster,
                        isActive: workflowActiveStep == 3,
                        icon: "square.and.arrow.down",
                        identifier: "vf.poster.workflowGuide.step3"
                    )
                }
            }
        }
        .accessibilityIdentifier("vf.poster.workflowGuide")
    }

    private func workflowStep(
        number: Int,
        title: String,
        subtitle: String,
        isCompleted: Bool,
        isActive: Bool,
        icon: String,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? VFStyle.teal.opacity(0.2) : isActive ? VFStyle.primaryRed.opacity(0.18) : .white.opacity(0.52))
                        .frame(width: 19, height: 19)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(VFStyle.teal)
                    } else {
                        Text(String(number))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(isActive ? VFStyle.primaryRed : VFStyle.secondaryText)
                    }
                }

                Image(systemName: icon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(isActive ? VFStyle.primaryRed : VFStyle.secondaryText)
            }

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(VFStyle.ink)
                .lineLimit(1)

            Text(subtitle)
                .font(.caption2.weight(.medium))
                .foregroundStyle(VFStyle.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private var workflowConnector: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.black))
            .foregroundStyle(VFStyle.secondaryText.opacity(0.5))
            .padding(.top, 8)
    }

    private var hasGeneratedBackground: Bool {
        poster.backgroundImageURL != nil
    }

    private var hasRenderedPoster: Bool {
        exportedImageURL != nil
    }

    private var workflowActiveStep: Int {
        if hasRenderedPoster { 3 }
        else if hasGeneratedBackground { 2 }
        else { 1 }
    }

    private var backgroundGenerationControls: some View {
        VFGlassCard {
            VStack(spacing: 12) {
                VFSectionHeader(
                    title: AppText.localized("AI Background", "AI 背景"),
                    subtitle: AppText.localized("Generate AI background only. This is the no-text commercial photo layer.", "仅生成背景图，不会写入文案，适合商单视觉素材。")
                )

                VFPrimaryButton(
                    title: appModel.isGeneratingPosterBackground ? AppText.localized("Generating Background...", "生成背景中...") : AppText.localized("Generate AI Background", "生成 AI 背景"),
                    icon: "sparkles.rectangle.stack",
                    isLoading: appModel.isGeneratingPosterBackground,
                    isEnabled: !appModel.isGeneratingPosterBackground
                ) {
                    generateBackgroundOnly()
                }
                .accessibilityIdentifier("vf.poster.generateBackgroundButton")

                if poster.backgroundImageURL != nil {
                    Button {
                        generateBackgroundOnly()
                    } label: {
                        Label(
                            appModel.isGeneratingPosterBackground
                                ? AppText.localized("Refreshing Background...", "正在更换背景...")
                                : AppText.localized("Regenerate Background Only", "只换背景图"),
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(VFStyle.primaryRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(VFStyle.primaryRed.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(VFStyle.primaryRed.opacity(0.24), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(appModel.isGeneratingPosterBackground)
                    .accessibilityIdentifier("vf.poster.regenerateBackgroundOnlyButton")
                }

                if let backgroundStatusMessage {
                    Label(backgroundStatusMessage, systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VFStyle.teal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("vf.poster.backgroundStatus")
                }

                if let posterGenerationError = appModel.posterGenerationError {
                    VFGlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(posterGenerationError, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(VFStyle.warning)
                            Text(AppText.localized(
                                "Your poster text and layout are still safe. You can retry AI background generation or render the current poster manually.",
                                "当前海报文案和版式不会丢失。你可以重试 AI 背景，也可以直接生成当前海报。"
                            ))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(VFStyle.secondaryText)

                            Button {
                                generateBackgroundOnly()
                            } label: {
                                Label(AppText.localized("Retry AI Background", "重试 AI 背景"), systemImage: "arrow.clockwise")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(VFStyle.primaryRed)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background(VFStyle.primaryRed.opacity(0.10), in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(appModel.isGeneratingPosterBackground)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityIdentifier("vf.poster.backgroundError")
                }
            }
        }
    }

    private var posterFormatControls: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Poster Layout", "版式与风格"),
                    subtitle: AppText.localized("Choose template style and export size", "选择海报风格与导出尺寸")
                )

                Picker(AppText.localized("Template", "模板"), selection: $poster.style) {
                    ForEach(PosterStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                Picker(AppText.localized("Size", "尺寸"), selection: $selectedTarget) {
                    ForEach(PosterCanvasTarget.allCases) { target in
                        Text(target.displayName).tag(target)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var productImageLockNotice: some View {
        VFGlassCard(level: .thick) {
            HStack(spacing: 12) {
                VFGradientIcon(icon: "lock.shield", tint: VFStyle.teal, size: 34)
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppText.localized("Real product lock", "真实产品已锁定"))
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                    Text(AppText.localized(
                        "Real product locked. AI backgrounds will be built around it.",
                        "已锁定真实产品，AI 背景会围绕该产品自然融合"
                    ))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)
                    .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var advancedPosterSettings: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showAdvancedSettings.toggle()
                    }
                } label: {
                    HStack {
                        VFSectionHeader(
                            title: AppText.localized("Advanced Settings", "高级设置"),
                            subtitle: AppText.localized("Style, product blend, copy position, directions, and history.", "样式、产品融合、文案位置、方向与历史版本设置")
                        )
                        Spacer(minLength: 0)
                        Image(systemName: showAdvancedSettings ? "chevron.down" : "chevron.right")
                            .foregroundStyle(VFStyle.secondaryText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.poster.advancedSettings")

                if showAdvancedSettings {
                    VStack(spacing: 12) {
                        posterFormatControls
                        productIntegrationControls
                        textPlacementControls
                        backgroundDirectionControls

                        if poster.backgroundHistory.count > 1 {
                            backgroundHistoryView
                        }

                        if directionPreviewVersions.count > 1 {
                            directionPreviewGrid
                        }
                    }
                }
            }
        }
    }

    private var productIntegrationControls: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 13) {
                VFSectionHeader(
                    title: AppText.localized("Product Blend", "产品融合"),
                    subtitle: AppText.localized("Balance real product fidelity with scene integration", "控制真实产品外观与场景融合")
                )

                HStack(spacing: 8) {
                    Text(AppText.localized("Mode", "模式"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)
                    Text(poster.productImageIntegrationMode.displayName)
                        .font(.caption.weight(.black))
                        .foregroundStyle(poster.productImageIntegrationMode.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(poster.productImageIntegrationMode.tint.opacity(0.12), in: Capsule())
                        .accessibilityIdentifier("vf.poster.productIntegrationStatus")
                }

                HStack(spacing: 10) {
                    ForEach(ProductImageIntegrationMode.allCases) { mode in
                        productIntegrationButton(mode)
                    }
                }
            }
        }
    }

    private func productIntegrationButton(_ mode: ProductImageIntegrationMode) -> some View {
        let isSelected = poster.productImageIntegrationMode == mode

        return Button {
            selectProductIntegrationMode(mode)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                VFGradientIcon(icon: mode.icon, tint: mode.tint, size: 34)
                Text(mode.displayName)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                Text(mode.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? mode.tint : VFStyle.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .padding(12)
            .background(isSelected ? mode.tint.opacity(0.12) : .white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? mode.tint.opacity(0.38) : .white.opacity(0.78), lineWidth: isSelected ? 1.4 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("vf.poster.productIntegration.\(mode.accessibilitySuffix)")
    }

    private var backgroundDirectionControls: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 13) {
                VFSectionHeader(
                    title: AppText.localized("Background Direction", "背景方向"),
                    subtitle: AppText.localized("Choose the visual bias before generating", "生成前选择画面倾向")
                )

                HStack(spacing: 8) {
                    Text(AppText.localized("Selected", "已选择"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)
                    Text(poster.backgroundDirection.displayName)
                        .font(.caption.weight(.black))
                        .foregroundStyle(poster.backgroundDirection.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(poster.backgroundDirection.tint.opacity(0.12), in: Capsule())
                        .accessibilityIdentifier("vf.poster.backgroundDirectionStatus")
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(PosterBackgroundDirection.allCases) { direction in
                        backgroundDirectionButton(direction)
                    }
                }

                Label(directionPreviewQuotaHintText, systemImage: directionPreviewGenerationLimit > 0 ? "bolt.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(directionPreviewGenerationLimit > 0 ? VFStyle.secondaryText : VFStyle.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("vf.poster.directionPreviewQuotaHint")

                Button {
                    generateDirectionPreviews()
                } label: {
                    Label(
                        isGeneratingDirectionPreviews
                            ? AppText.localized("Generating Previews...", "正在生成预览...")
                            : directionPreviewButtonTitle,
                        systemImage: "rectangle.grid.2x2.fill"
                    )
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(VFStyle.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingDirectionPreviews || appModel.isGeneratingPosterBackground || directionPreviewGenerationLimit == 0)
                .accessibilityIdentifier("vf.poster.generateDirectionPreviewsButton")
            }
        }
    }

    private func backgroundDirectionButton(_ direction: PosterBackgroundDirection) -> some View {
        let isSelected = poster.backgroundDirection == direction

        return Button {
            selectBackgroundDirection(direction)
        } label: {
            HStack(spacing: 10) {
                VFGradientIcon(icon: direction.icon, tint: direction.tint, size: 34)
                Text(direction.displayName)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(isSelected ? direction.tint.opacity(0.12) : .white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? direction.tint.opacity(0.38) : .white.opacity(0.78), lineWidth: isSelected ? 1.4 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("vf.poster.backgroundDirection.\(direction.accessibilitySuffix)")
    }

    private var textPlacementControls: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 13) {
                VFSectionHeader(
                    title: AppText.localized("Copy Safety", "文案避让"),
                    subtitle: AppText.localized("Move poster copy away from the product hero", "让文字避开产品主体，减少遮挡")
                )

                HStack(spacing: 10) {
                    ForEach(PosterTextPlacement.allCases) { placement in
                        textPlacementButton(placement)
                    }
                }
            }
        }
    }

    private func textPlacementButton(_ placement: PosterTextPlacement) -> some View {
        let isSelected = poster.textPlacement == placement
        let tint = placement == .automatic ? VFStyle.teal : VFStyle.electricCyan

        return Button {
            selectTextPlacement(placement)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                VFGradientIcon(icon: placement.icon, tint: tint, size: 32)
                Text(placement.displayName)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Text(placement.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? tint : VFStyle.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(12)
            .background(isSelected ? tint.opacity(0.12) : .white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? tint.opacity(0.38) : .white.opacity(0.78), lineWidth: isSelected ? 1.4 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("vf.poster.textPlacement.\(placement.accessibilitySuffix)")
    }

    private var directionPreviewGenerationLimit: Int {
        let totalDirections = PosterBackgroundDirection.allCases.count
        guard !appModel.quota.isPro else { return totalDirections }
        return min(totalDirections, max(0, appModel.quota.remainingPosterExports))
    }

    private var directionPreviewButtonTitle: String {
        guard directionPreviewGenerationLimit > 0 else {
            return AppText.localized("Upgrade for Direction Previews", "升级生成方向预览")
        }
        return AppText.localized(
            "Generate \(directionPreviewGenerationLimit) Direction Previews",
            "生成 \(directionPreviewGenerationLimit) 张方向预览"
        )
    }

    private var directionPreviewQuotaHintText: String {
        if appModel.quota.isPro {
            return AppText.localized(
                "Pro can generate 4 direction previews.",
                "会员可生成 4 张方向预览"
            )
        }
        if directionPreviewGenerationLimit == 0 {
            return AppText.localized(
                "No AI background quota left today.",
                "今日 AI 背景额度已用完"
            )
        }
        return AppText.localized(
            "Estimated cost: \(directionPreviewGenerationLimit) AI background credits",
            "预计消耗 \(directionPreviewGenerationLimit) 次 AI 背景额度"
        )
    }

    private var exportOptions: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 13) {
                VFSectionHeader(
                    title: AppText.localized("Render & Export", "渲染与导出"),
                    subtitle: AppText.localized("Render creates the final poster for sharing and publishing.", "点击生成后会导出最终可分享的海报。")
                )

                HStack(spacing: 10) {
                    exportModeButton(
                        title: AppText.localized("Branded", "带标识"),
                        subtitle: AppText.localized("Free", "免费"),
                        icon: "sparkles",
                        tint: VFStyle.electricCyan,
                        isSelected: showsWatermarkForExport
                    ) {
                        exportMode = .watermarked
                    }

                    exportModeButton(
                        title: AppText.localized("No Watermark", "无水印"),
                        subtitle: appModel.quota.isPro ? "Pro" : AppText.localized("Pro only", "会员专享"),
                        icon: appModel.quota.isPro ? "checkmark.seal.fill" : "lock.fill",
                        tint: appModel.quota.isPro ? VFStyle.teal : VFStyle.sunset,
                        isSelected: !showsWatermarkForExport
                    ) {
                        if appModel.quota.isPro {
                            exportMode = .clean
                        } else {
                            requestCleanExport()
                        }
                    }
                }
            }
        }
    }

    private var backgroundHistoryView: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VFSectionHeader(
                    title: AppText.localized("Background Versions", "背景版本"),
                    subtitle: AppText.localized("Compare recent AI backgrounds without changing poster copy", "切换近期 AI 背景，海报文案不变")
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(poster.backgroundHistory.enumerated()), id: \.element.id) { index, version in
                            backgroundVersionButton(version, index: index)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("vf.poster.backgroundHistory")
        }
    }

    private var directionPreviewVersions: [PosterBackgroundVersion] {
        PosterBackgroundDirection.allCases.compactMap { direction in
            poster.backgroundHistory.first { $0.backgroundDirection == direction }
        }
    }

    private var directionPreviewGrid: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VFSectionHeader(
                    title: AppText.localized("Direction Preview", "方向预览"),
                    subtitle: AppText.localized("Pick the background that fits the real product best", "选择最适合真实产品的一张背景")
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(directionPreviewVersions) { version in
                            directionPreviewButton(version)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("vf.poster.directionPreviewGrid")
        }
    }

    private func directionPreviewButton(_ version: PosterBackgroundVersion) -> some View {
        let direction = version.backgroundDirection ?? .clean
        let isSelected = poster.backgroundImageURL == version.imageURL

        return Button {
            selectBackgroundVersion(version)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: version.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        versionFallbackThumbnail(isSelected: isSelected)
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        versionFallbackThumbnail(isSelected: isSelected)
                    }
                }
                .frame(width: 118, height: 156)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? direction.tint.opacity(0.72) : .white.opacity(0.86), lineWidth: isSelected ? 2.4 : 1)
                }

                Label(direction.displayName, systemImage: direction.icon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(isSelected ? direction.tint : VFStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .frame(width: 118)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction.displayName)
        .accessibilityIdentifier("vf.poster.directionPreview")
    }

    private func backgroundVersionButton(_ version: PosterBackgroundVersion, index: Int) -> some View {
        let isSelected = poster.backgroundImageURL == version.imageURL

        return Button {
            selectBackgroundVersion(version)
        } label: {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: version.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        versionFallbackThumbnail(isSelected: isSelected)
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        versionFallbackThumbnail(isSelected: isSelected)
                    }
                }
                .frame(width: 84, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? VFStyle.primaryRed : .white.opacity(0.86), lineWidth: isSelected ? 2.4 : 1)
                }

                Text(index == 0 ? AppText.localized("Now", "当前") : "\(index + 1)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(isSelected ? .white : VFStyle.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(isSelected ? VFStyle.primaryRed : .white.opacity(0.82), in: Capsule())
                    .padding(6)
            }
            .shadow(color: VFStyle.primaryRed.opacity(isSelected ? 0.18 : 0.06), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(index == 0 ? AppText.localized("Current background version", "当前背景版本") : AppText.localized("Background version \(index + 1)", "背景版本 \(index + 1)"))
        .accessibilityIdentifier("vf.poster.backgroundVersion")
    }

    private func versionFallbackThumbnail(isSelected: Bool) -> some View {
        LinearGradient(
            colors: isSelected
                ? [VFStyle.primaryRed.opacity(0.16), VFStyle.sunset.opacity(0.20)]
                : [VFStyle.electricCyan.opacity(0.13), VFStyle.teal.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var exportResultHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            VFGradientIcon(
                icon: showsWatermarkForExport ? "sparkles" : "checkmark.seal.fill",
                tint: showsWatermarkForExport ? VFStyle.electricCyan : VFStyle.teal,
                size: 34
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(showsWatermarkForExport ? AppText.localized("Branded export ready", "带标识图片已生成") : AppText.localized("No-watermark export ready", "无水印图片已生成"))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                Text(showsWatermarkForExport ? AppText.localized("Upgrade to Pro anytime to remove the ViralForge mark.", "可随时升级 Pro 移除 ViralForge 标识。") : AppText.localized("Ready for direct publishing and client delivery.", "可直接发布或交付客户。"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)

                Text(AppText.localized("Share first, then save, or render a no-watermark version.", "建议先分享/保存，或者直接渲染无水印版本。"))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exportModeButton(title: String, subtitle: String, icon: String, tint: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VFGradientIcon(icon: icon, tint: tint, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                    Text(subtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? tint : VFStyle.secondaryText)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? tint.opacity(0.10) : .white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? tint.opacity(0.34) : .white.opacity(0.78), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func exportActionLabel(_ title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white.opacity(0.62), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            }
    }

    private func posterField(
        _ placeholder: String,
        text: Binding<String>,
        icon: String,
        tint: Color,
        lines: Int = 1,
        accessibilityIdentifier: String = ""
    ) -> some View {
        HStack(alignment: lines > 1 ? .top : .center, spacing: 12) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(lines, reservesSpace: lines > 1)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.82), lineWidth: 1)
                }
                .accessibilityIdentifier(accessibilityIdentifier)
        }
    }

    private var showsWatermarkForExport: Bool {
        !appModel.quota.isPro || exportMode == .watermarked
    }

    private var posterChannelLabelBinding: Binding<String> {
        Binding(
            get: {
                poster.resolvedChannelLabel(for: project.draft.platform)
            },
            set: { newValue in
                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                mutatePoster {
                    $0.channelLabel = trimmedValue.isEmpty ? nil : trimmedValue
                }
            }
        )
    }

    private var posterHeadlineBinding: Binding<String> {
        Binding(
            get: { poster.headline },
            set: { newValue in
                mutatePoster { $0.headline = newValue }
            }
        )
    }

    private var posterSubtitleBinding: Binding<String> {
        Binding(
            get: { poster.subtitle },
            set: { newValue in
                mutatePoster { $0.subtitle = newValue }
            }
        )
    }

    private var posterCtaBinding: Binding<String> {
        Binding(
            get: { poster.cta },
            set: { newValue in
                mutatePoster { $0.cta = newValue }
            }
        )
    }

    private var posterTextFontFamilyBinding: Binding<PosterTextFontFamily> {
        Binding(
            get: { poster.textFontFamily },
            set: { newValue in
                mutatePoster { $0.textFontFamily = newValue }
            }
        )
    }

    private var posterTextWeightBinding: Binding<PosterTextWeight> {
        Binding(
            get: { poster.textWeight },
            set: { newValue in
                mutatePoster { $0.textWeight = newValue }
            }
        )
    }

    private var posterTextColorBinding: Binding<PosterTextColor> {
        Binding(
            get: { poster.textColor },
            set: { newValue in
                mutatePoster { $0.textColor = newValue }
            }
        )
    }

    private var posterTextAlignmentBinding: Binding<PosterTextAlignment> {
        Binding(
            get: { poster.textAlignment },
            set: { newValue in
                mutatePoster { $0.textAlignment = newValue }
            }
        )
    }

    private var posterHeadlineScaleBinding: Binding<Double> {
        Binding(
            get: { poster.clampedHeadlineScale },
            set: { newValue in
                mutatePoster { $0.headlineScale = newValue }
            }
        )
    }

    private var posterSubtitleScaleBinding: Binding<Double> {
        Binding(
            get: { poster.clampedSubtitleScale },
            set: { newValue in
                mutatePoster { $0.subtitleScale = newValue }
            }
        )
    }

    private var posterCtaScaleBinding: Binding<Double> {
        Binding(
            get: { poster.clampedCtaScale },
            set: { newValue in
                mutatePoster { $0.ctaScale = newValue }
            }
        )
    }

    private var posterCopyOffsetXBinding: Binding<Double> {
        Binding(
            get: { poster.clampedCopyOffsetX },
            set: { newValue in
                mutatePoster { $0.copyOffsetX = newValue }
            }
        )
    }

    private var posterCopyOffsetYBinding: Binding<Double> {
        Binding(
            get: { poster.clampedCopyOffsetY },
            set: { newValue in
                mutatePoster { $0.copyOffsetY = newValue }
            }
        )
    }

    private func resetTextLayerSettings() {
        mutatePoster {
            $0.textFontFamily = .rounded
            $0.textWeight = .black
            $0.textColor = .auto
            $0.textAlignment = .leading
            $0.headlineScale = 1.0
            $0.subtitleScale = 1.0
            $0.ctaScale = 1.0
            $0.copyOffsetX = 0.0
            $0.copyOffsetY = 0.0
        }
    }

    private func mutatePoster(
        statusMessage: String? = nil,
        clearExport: Bool = true,
        _ mutate: (inout PosterDraft) -> Void
    ) {
        mutate(&poster)

        if clearExport {
            exportedUIImage = nil
            exportedImageURL = nil
        }

        if let statusMessage {
            backgroundStatusMessage = statusMessage
        } else if clearExport {
            backgroundStatusMessage = nil
        }

        Task {
            await appModel.savePosterDraft(for: project, poster: poster)
        }
    }

    private func selectBackgroundDirection(_ direction: PosterBackgroundDirection) {
        guard poster.backgroundDirection != direction else { return }
        mutatePoster {
            $0.backgroundDirection = direction
        }
    }

    private func selectProductIntegrationMode(_ mode: ProductImageIntegrationMode) {
        guard poster.productImageIntegrationMode != mode else { return }
        mutatePoster {
            $0.productImageIntegrationMode = mode
        }
    }

    private func selectTextPlacement(_ placement: PosterTextPlacement) {
        guard poster.textPlacement != placement else { return }
        mutatePoster(
            statusMessage: AppText.localized(
                "Copy placement updated. Regenerate the background for better product clearance.",
                "文案位置已更新。重新生成背景后，产品避让效果会更好。"
            )
        ) {
            $0.textPlacement = placement
        }
    }

    private func applyTitleCandidate(_ line: ScoredLine) {
        selectedTitleID = line.id
        mutatePoster(
            statusMessage: AppText.localized(
                "Title applied to poster copy.",
                "标题已应用到海报文案。"
            )
        ) {
            $0.headline = line.text
        }
    }

    private func applyHookCandidate(_ line: ScoredLine) {
        selectedHookID = line.id
        mutatePoster(
            statusMessage: AppText.localized(
                "Hook applied to poster subtitle.",
                "开头钩子已应用到海报副标题。"
            )
        ) {
            $0.subtitle = line.text
        }
    }

    private func generateDirectionPreviews() {
        guard !isGeneratingDirectionPreviews else { return }
        let generationLimit = directionPreviewGenerationLimit
        guard generationLimit > 0 else {
            let message = AppText.localized(
                "AI background quota is used up. Upgrade to Pro to generate direction previews.",
                "AI 背景额度已用完。升级 Pro 后可生成方向预览。"
            )
            appModel.posterGenerationError = message
            appModel.openPaywall(reason: message)
            return
        }

        guard generationLimit <= 1 || ProcessInfo.processInfo.arguments.contains("VF_UI_TESTING") else {
            showsDirectionPreviewCostAlert = true
            return
        }

        runDirectionPreviews(generationLimit: generationLimit)
    }

    private func runDirectionPreviews(generationLimit: Int) {
        Task {
            isGeneratingDirectionPreviews = true
            defer { isGeneratingDirectionPreviews = false }

            var latestPoster = poster
            var generatedCount = 0
            for direction in PosterBackgroundDirection.allCases.prefix(generationLimit) {
                var directionPoster = latestPoster
                directionPoster.backgroundDirection = direction
                guard let updatedPoster = await appModel.generatePosterBackground(
                    for: project,
                    poster: directionPoster,
                    aspectRatio: selectedTarget.apiAspectRatio
                ) else {
                    break
                }

                latestPoster = updatedPoster
                generatedCount += 1
            }

            guard generatedCount > 0 else { return }
            poster = latestPoster
            exportedUIImage = nil
            exportedImageURL = nil
            backgroundStatusMessage = AppText.localized(
                "\(generatedCount) direction previews generated. Pick the background that fits best.",
                "\(generatedCount) 张方向预览已生成，选择最合适的一张背景。"
            )
        }
    }

    private func requestCleanExport() {
        guard appModel.quota.isPro else {
            appModel.openPaywall(reason: AppText.localized(
                "No-watermark poster export is included in ViralForge Pro.",
                "无水印海报导出是 ViralForge Pro 会员权益。"
            ))
            return
        }

        exportMode = .clean
        exportPoster()
    }

    private func generateBackgroundOnly() {
        Task {
            guard let updatedPoster = await appModel.generatePosterBackground(for: project, poster: poster, aspectRatio: selectedTarget.apiAspectRatio) else {
                return
            }

            poster = updatedPoster
            exportedUIImage = nil
            exportedImageURL = nil
            backgroundStatusMessage = AppText.localized(
                "Background refreshed. Poster copy was kept unchanged.",
                "背景已更换，海报文案保持不变。"
            )
        }
    }

    private func selectBackgroundVersion(_ version: PosterBackgroundVersion) {
        poster = poster.selectingBackgroundVersion(version)
        exportedUIImage = nil
        exportedImageURL = nil
        backgroundStatusMessage = AppText.localized(
            "Background version selected. Poster copy was kept unchanged.",
            "已切换背景版本，海报文案保持不变。"
        )

        Task {
            await appModel.savePosterDraft(for: project, poster: poster)
        }
    }

    @MainActor
    private func exportPoster() {
        guard !isRenderingExport else { return }
        if exportMode == .clean && !appModel.quota.isPro {
            requestCleanExport()
            return
        }

        Task {
            await renderPosterExport()
        }
    }

    @MainActor
    private func renderPosterExport() async {
        isRenderingExport = true
        exportStatusMessage = AppText.localized("Preparing poster image...", "正在准备海报图片...")
        defer { isRenderingExport = false }

        let exportBackgroundImage = await loadedExportBackgroundImage()
        if poster.backgroundImageURL != nil && exportBackgroundImage == nil {
            exportStatusMessage = AppText.localized(
                "Poster background is still loading. Please check the network and render again.",
                "海报背景图还未加载成功，请检查网络后重新生成。"
            )
            return
        }

        let exportSize = selectedTarget.exportSize
        let renderer = ImageRenderer(
            content: PosterPreview(
                poster: poster,
                platform: project.draft.platform,
                target: selectedTarget,
                showsWatermark: showsWatermarkForExport,
                preloadedBackgroundImage: exportBackgroundImage
            )
            .frame(width: exportSize.width, height: exportSize.height)
        )
        renderer.scale = 1
        guard let uiImage = renderer.uiImage else {
            exportStatusMessage = AppText.localized("Poster export failed.", "海报导出失败。")
            return
        }

        exportedUIImage = uiImage
        exportedImageURL = await writePNGToTemporaryFile(uiImage)
        exportStatusMessage = showsWatermarkForExport
            ? AppText.localized("Poster rendered with ViralForge mark. It is now available in Assets.", "带 ViralForge 标识的海报已生成，可在素材库查看。")
            : AppText.localized("No-watermark poster rendered. It is now available in Assets.", "无水印海报已生成，可在素材库查看。")

        Task {
            await appModel.savePosterDraft(for: project, poster: poster, markExported: true)
        }
    }

    private func loadedExportBackgroundImage() async -> UIImage? {
        guard let backgroundImageURL = poster.backgroundImageURL else { return nil }

        if backgroundImageURL.scheme == "data",
           let dataURLImage = imageFromDataURL(backgroundImageURL) {
            return dataURLImage
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: backgroundImageURL)
            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func imageFromDataURL(_ url: URL) -> UIImage? {
        let absoluteString = url.absoluteString
        guard let commaIndex = absoluteString.firstIndex(of: ",") else { return nil }
        let metadata = absoluteString[..<commaIndex]
        let payload = String(absoluteString[absoluteString.index(after: commaIndex)...])

        let data: Data?
        if metadata.contains(";base64") {
            data = Data(base64Encoded: payload)
        } else {
            data = payload.removingPercentEncoding?.data(using: .utf8)
        }

        return data.flatMap(UIImage.init(data:))
    }

    private func writePNGToTemporaryFile(_ image: UIImage) async -> URL? {
        let fileName = "viralforge-poster-\(project.id.uuidString).png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            guard let data = await Task.detached(priority: .utility, operation: {
                image.pngData()
            }).value else {
                return nil
            }
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            exportStatusMessage = AppText.localized(
                "PNG file export failed: \(error.localizedDescription)",
                "PNG 文件导出失败：\(error.localizedDescription)"
            )
            return nil
        }
    }

    private func saveToPhotoLibrary() {
        guard let exportedUIImage else { return }

        isSavingToPhotos = true
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: exportedUIImage)
        } completionHandler: { success, error in
            Task { @MainActor in
                isSavingToPhotos = false
                if success {
                    exportStatusMessage = AppText.localized("Saved to Photos.", "已保存到相册。")
                } else {
                    exportStatusMessage = AppText.localized(
                        "Photo save failed: \(error?.localizedDescription ?? "Unknown error")",
                        "保存到相册失败：\(error?.localizedDescription ?? "未知错误")"
                    )
                }
            }
        }
    }
}

private struct CopyCandidateButton: View {
    let line: ScoredLine
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(isSelected ? tint : VFStyle.secondaryText.opacity(0.42))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(line.text)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                        Text(AppText.localized("Score \(line.score)", "推荐 \(line.score)"))
                    }
                    .font(.caption2.weight(.black))
                    .foregroundStyle(tint)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background(isSelected ? tint.opacity(0.10) : .white.opacity(0.46), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? tint.opacity(0.28) : .white.opacity(0.72), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(line.text)
    }
}

struct PosterPreview: View {
    let poster: PosterDraft
    let platform: SocialPlatform
    let target: PosterCanvasTarget
    let showsWatermark: Bool
    let preloadedBackgroundImage: UIImage?
    let productUIImage: UIImage?

    init(
        poster: PosterDraft,
        platform: SocialPlatform,
        target: PosterCanvasTarget = .xiaohongshuCover,
        showsWatermark: Bool = false,
        preloadedBackgroundImage: UIImage? = nil
    ) {
        self.poster = poster
        self.platform = platform
        self.target = target
        self.showsWatermark = showsWatermark
        self.preloadedBackgroundImage = preloadedBackgroundImage
        self.productUIImage = poster.productImageData.flatMap(UIImage.init(data:))
    }

    var body: some View {
        let palette = poster.style.palette

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(palette.background)
            if poster.backgroundImageURL == nil {
                PosterFallbackVisual(palette: palette, platform: platform)
            }
            if let preloadedBackgroundImage {
                Image(uiImage: preloadedBackgroundImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let backgroundImageURL = poster.backgroundImageURL,
                      backgroundImageURL.scheme == "data",
                      let dataURLImage = Self.imageFromDataURL(backgroundImageURL) {
                Image(uiImage: dataURLImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let backgroundImageURL = poster.backgroundImageURL {
                AsyncImage(url: backgroundImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        PosterFallbackVisual(palette: palette, platform: platform)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        palette.background
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            if hasImageBackground {
                readabilityScrim(palette: palette)
            } else {
                LinearGradient(
                    colors: [
                        palette.background.opacity(0),
                        palette.background.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            if poster.shouldOverlayProductImage, let productUIImage {
                productImageLayer(productUIImage, palette: palette)
            }
            posterContentOverlay(palette: palette)
            if showsWatermark {
                posterWatermark(palette: palette)
            }
        }
        .aspectRatio(target.aspectRatio, contentMode: .fit)
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    private var resolvedTextPlacement: PosterTextPlacement {
        poster.textPlacement.resolved(for: poster)
    }

    private var hasImageBackground: Bool {
        poster.backgroundImageURL != nil
    }

    private static func imageFromDataURL(_ url: URL) -> UIImage? {
        let absoluteString = url.absoluteString
        guard let commaIndex = absoluteString.firstIndex(of: ",") else { return nil }
        let metadata = absoluteString[..<commaIndex]
        let payload = String(absoluteString[absoluteString.index(after: commaIndex)...])
        let data = metadata.contains(";base64")
            ? Data(base64Encoded: payload)
            : payload.removingPercentEncoding?.data(using: .utf8)
        return data.flatMap(UIImage.init(data:))
    }

    private var placesCopyAtTop: Bool {
        resolvedTextPlacement == .top
    }

    private var usesProductSafeTextLayout: Bool {
        poster.productImageData != nil || poster.productImageIntegratedInBackground == true
    }

    private var copyHorizontalAlignment: HorizontalAlignment {
        poster.textAlignment.horizontalAlignment
    }

    private var copyTextAlignment: TextAlignment {
        poster.textAlignment.textAlignment
    }

    private var copyFrameAlignment: Alignment {
        poster.textAlignment.frameAlignment
    }

    private var headlineScale: CGFloat {
        CGFloat(poster.clampedHeadlineScale)
    }

    private var subtitleScale: CGFloat {
        CGFloat(poster.clampedSubtitleScale)
    }

    private var ctaScale: CGFloat {
        CGFloat(poster.clampedCtaScale)
    }

    private func copyOffsetX(_ width: CGFloat) -> CGFloat {
        max(min(CGFloat(poster.clampedCopyOffsetX), width * 0.35), -width * 0.35)
    }

    private func copyOffsetY(_ height: CGFloat) -> CGFloat {
        max(min(CGFloat(poster.clampedCopyOffsetY), height * 0.35), -height * 0.35)
    }

    private func copyForegroundColor(palette: PosterPalette, isButtonText: Bool = false) -> Color {
        poster.textColor.resolvedColor(
            palette: palette,
            hasImageBackground: hasImageBackground,
            isButtonText: isButtonText
        )
    }

    private func copyFont(size: CGFloat) -> Font {
        Font.system(
            size: size,
            weight: poster.textWeight.weight,
            design: poster.textFontFamily.design
        )
    }

    private var productPriorityTitleLineLimit: Int {
        usesProductSafeTextLayout ? 2 : 3
    }

    @ViewBuilder
    private func readabilityScrim(palette: PosterPalette) -> some View {
        ZStack {
            LinearGradient(
                colors: placesCopyAtTop
                    ? [
                        .black.opacity(0.56),
                        .black.opacity(0.32),
                        .clear,
                        .black.opacity(0.20)
                    ]
                    : [
                        .black.opacity(0.18),
                        .clear,
                        .black.opacity(0.28),
                        .black.opacity(0.54)
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    (placesCopyAtTop ? palette.background : palette.primary).opacity(0.12),
                    .clear,
                    .clear,
                    (placesCopyAtTop ? palette.primary : palette.background).opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func adjustedTitleSize(_ baseSize: CGFloat) -> CGFloat {
        let targetScale: CGFloat
        switch target {
        case .xiaohongshuCover:
            targetScale = 0.92
        case .douyinVertical:
            targetScale = 0.86
        case .weChatSquare:
            targetScale = 0.80
        }

        return baseSize * targetScale * (usesProductSafeTextLayout ? 0.88 : 1)
    }

    private func productImageLayer(_ image: UIImage, palette: PosterPalette) -> some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.54, proxy.size.height * 0.36)
            let height = min(proxy.size.height * 0.30, width * 1.08)
            let topPadding = max(64, proxy.size.height * 0.12)
            let bottomPadding = max(36, proxy.size.height * 0.07)
            let sidePadding = max(22, proxy.size.width * 0.07)
            let productImage = Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(max(8, width * 0.055))
                .frame(width: width, height: height)
                .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.92), lineWidth: 1)
                }
                .shadow(color: palette.primary.opacity(0.18), radius: 18, x: 0, y: 10)
                .rotationEffect(.degrees(poster.style == .editorial ? -2 : 2))

            VStack {
                if placesCopyAtTop {
                    Spacer()
                    HStack {
                        Spacer()
                        productImage
                    }
                    .padding(.bottom, bottomPadding)
                } else {
                    HStack {
                        Spacer()
                        productImage
                    }
                    .padding(.top, topPadding)
                    Spacer()
                }
            }
            .padding(.trailing, sidePadding)
            .allowsHitTesting(false)
            .accessibilityIdentifier("vf.poster.productImageLayer")
        }
    }

    @ViewBuilder
    private func posterContentOverlay(palette: PosterPalette) -> some View {
        GeometryReader { proxy in
            if usesProductSafeTextLayout {
                productSafeCopyOverlay(palette: palette, width: proxy.size.width, height: proxy.size.height)
                    .offset(
                        x: copyOffsetX(proxy.size.width),
                        y: copyOffsetY(proxy.size.height)
                    )
            } else {
                standardPosterContentOverlay(palette: palette, width: proxy.size.width, height: proxy.size.height)
                    .offset(
                        x: copyOffsetX(proxy.size.width),
                        y: copyOffsetY(proxy.size.height)
                    )
            }
        }
    }

    @ViewBuilder
    private func standardPosterContentOverlay(
        palette: PosterPalette,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let contentAlignment = copyFrameAlignment
        switch poster.style {
        case .cleanProduct:
            VStack(alignment: copyHorizontalAlignment, spacing: 18) {
                platformBadge(palette: palette)
                if placesCopyAtTop {
                    cleanCopyBlock(palette: palette)
                    Spacer()
                } else {
                    Spacer()
                    cleanCopyBlock(palette: palette)
                }
            }
            .padding(28)
            .frame(maxWidth: width, maxHeight: height, alignment: contentAlignment)
        case .boldLaunch:
            VStack(alignment: copyHorizontalAlignment, spacing: 18) {
                HStack {
                    platformBadge(palette: palette)
                    Spacer()
                    Text(AppText.localized("NEW", "上新"))
                        .font(.caption.weight(.black))
                        .foregroundStyle(palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.22), in: Capsule())
                }
                if placesCopyAtTop {
                    boldCopyBlock(palette: palette)
                    ctaButton(palette: palette, cornerRadius: 18)
                    Spacer()
                } else {
                    Spacer()
                    boldCopyBlock(palette: palette)
                    ctaButton(palette: palette, cornerRadius: 18)
                }
            }
            .padding(26)
            .frame(maxWidth: width, maxHeight: height, alignment: contentAlignment)
        case .softLifestyle:
            VStack(alignment: copyHorizontalAlignment, spacing: 16) {
                platformBadge(palette: palette)
                if placesCopyAtTop {
                    softCopyCard(palette: palette)
                    Spacer()
                } else {
                    Spacer()
                    softCopyCard(palette: palette)
                }
            }
            .padding(24)
            .frame(maxWidth: width, maxHeight: height, alignment: contentAlignment)
        case .editorial:
            VStack(alignment: copyHorizontalAlignment, spacing: 18) {
                platformBadge(palette: palette)
                if placesCopyAtTop {
                    editorialCopyBlock(palette: palette)
                    Spacer()
                } else {
                    Spacer()
                    editorialCopyBlock(palette: palette)
                }
            }
            .padding(28)
            .frame(maxWidth: width, maxHeight: height, alignment: contentAlignment)
        }
    }

    @ViewBuilder
    private func productSafeCopyOverlay(
        palette: PosterPalette,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let horizontalPadding = max(18, width * 0.055)
        let verticalPadding = max(14, height * 0.026)
        let cardPadding = max(12, width * 0.03)
        let copyCardMaxWidth = min(width * 0.68, max(260, width * 0.54))
        let safeAreaHeight = height * (placesCopyAtTop ? 0.35 : 0.32)
        let titleSize = min(29, max(20, width * (target == .weChatSquare ? 0.056 : 0.061)))
        let subtitleSize = min(16, max(12, width * 0.033))
        let ctaSize = min(15, max(12, width * 0.031))

        let cardTitleAlignment = copyHorizontalAlignment
        let cardCopyTextAlignment = copyTextAlignment
        let cardTitleColor = copyForegroundColor(palette: palette)
        let copySubtitleColor = copyForegroundColor(palette: palette).opacity(hasImageBackground ? 0.84 : 0.75)
        let ctaBackground = palette.accent

        let copyCard = VStack(alignment: cardTitleAlignment, spacing: max(6, height * 0.006)) {
            platformBadge(palette: palette)
                .frame(maxWidth: copyCardMaxWidth, alignment: copyFrameAlignment)
            Text(poster.headline)
                .font(copyFont(size: titleSize * headlineScale))
                .minimumScaleFactor(0.62)
                .lineLimit(2)
                .multilineTextAlignment(cardCopyTextAlignment)
                .foregroundStyle(cardTitleColor)
                .shadow(
                    color: hasImageBackground ? Color.black.opacity(0.52) : .clear,
                    radius: hasImageBackground ? 8 : 0,
                    x: 0,
                    y: 2
                )
            Text(poster.subtitle)
                .font(copyFont(size: subtitleSize * subtitleScale))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .multilineTextAlignment(cardCopyTextAlignment)
                .foregroundStyle(copySubtitleColor)
                .shadow(
                    color: hasImageBackground ? Color.black.opacity(0.42) : .clear,
                    radius: hasImageBackground ? 7 : 0,
                    x: 0,
                    y: 2
                )
            Text(poster.cta)
                .font(copyFont(size: ctaSize * ctaScale))
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .multilineTextAlignment(cardCopyTextAlignment)
                .padding(.horizontal, max(10, width * 0.024))
                .padding(.vertical, max(7, height * 0.007))
                .foregroundStyle(copyForegroundColor(palette: palette, isButtonText: true))
                .background(ctaBackground, in: RoundedRectangle(cornerRadius: 10))
                .shadow(
                    color: hasImageBackground ? Color.black.opacity(0.48) : .clear,
                    radius: hasImageBackground ? 10 : 0,
                    x: 0,
                    y: 4
                )
                .frame(maxWidth: .infinity, alignment: copyFrameAlignment)
        }
        .padding(cardPadding)
        .frame(maxWidth: copyCardMaxWidth, alignment: copyFrameAlignment)
        .background(
            hasImageBackground
                ? AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.black.opacity(0.34), Color.black.opacity(0.14)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                : AnyShapeStyle(Color.white.opacity(0.74)),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(hasImageBackground ? Color.white.opacity(0.42) : Color.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 7)

        VStack {
            if placesCopyAtTop {
                copyCard
                    .frame(maxHeight: safeAreaHeight)
                    .frame(maxWidth: .infinity, alignment: copyFrameAlignment)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                copyCard
                    .frame(maxHeight: safeAreaHeight)
                    .frame(maxWidth: .infinity, alignment: copyFrameAlignment)
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
    }

    private func cleanCopyBlock(palette: PosterPalette) -> some View {
        VStack(alignment: copyHorizontalAlignment, spacing: 12) {
            posterTitle(
                palette: palette,
                size: adjustedTitleSize(44),
                lineLimit: productPriorityTitleLineLimit
            )
            posterSubtitle(
                palette: palette,
                size: 20,
                lineLimit: usesProductSafeTextLayout ? 2 : nil
            )
            ctaButton(palette: palette, cornerRadius: 8)
        }
    }

    private func boldCopyBlock(palette: PosterPalette) -> some View {
        VStack(alignment: copyHorizontalAlignment, spacing: 12) {
            posterTitle(palette: palette, size: adjustedTitleSize(48), lineLimit: productPriorityTitleLineLimit)
            posterSubtitle(palette: palette, size: 20, lineLimit: 2)
        }
        .padding(18)
        .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: hasImageBackground ? .black.opacity(0.25) : .clear, radius: 12, x: 0, y: 6)
    }

    private func softCopyCard(palette: PosterPalette) -> some View {
        VStack(alignment: copyHorizontalAlignment, spacing: 12) {
            posterTitle(palette: palette, size: adjustedTitleSize(36), lineLimit: productPriorityTitleLineLimit)
            posterSubtitle(
                palette: palette,
                size: 20,
                lineLimit: usesProductSafeTextLayout ? 2 : nil
            )
            ctaButton(palette: palette, cornerRadius: 14)
        }
        .padding(18)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: hasImageBackground ? .black.opacity(0.20) : .clear, radius: 10, x: 0, y: 5)
    }

    private func editorialCopyBlock(palette: PosterPalette) -> some View {
        VStack(alignment: copyHorizontalAlignment, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Rectangle()
                    .fill(palette.accent)
                    .frame(width: 5)
                    .clipShape(Capsule())
                VStack(alignment: copyHorizontalAlignment, spacing: 12) {
                    posterTitle(palette: palette, size: adjustedTitleSize(42), lineLimit: productPriorityTitleLineLimit)
                    posterSubtitle(
                        palette: palette,
                        size: 20,
                        lineLimit: usesProductSafeTextLayout ? 2 : nil
                    )
                }
            }
            Text(poster.cta)
                .font(copyFont(size: 17 * ctaScale))
                .foregroundStyle(copyForegroundColor(palette: palette))
                .padding(.bottom, 4)
                .shadow(
                    color: hasImageBackground ? Color.black.opacity(0.42) : .clear,
                    radius: hasImageBackground ? 7 : 0,
                    x: 0,
                    y: 2
                )
                .multilineTextAlignment(copyTextAlignment)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(palette.accent)
                        .frame(height: 3)
                        .frame(maxWidth: .infinity, alignment: copyFrameAlignment)
                }
        }
    }

    private func platformBadge(palette: PosterPalette) -> some View {
        Text(poster.resolvedChannelLabel(for: platform).uppercased())
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(palette.background)
            .background(palette.accent, in: Capsule())
            .shadow(
                color: hasImageBackground ? Color.black.opacity(0.36) : .clear,
                radius: hasImageBackground ? 4 : 0,
                x: 0,
                y: 2
            )
            .accessibilityIdentifier("vf.poster.channelLabelBadge")
    }

    private func posterTitle(palette: PosterPalette, size: CGFloat, lineLimit: Int) -> some View {
        Text(poster.headline)
            .font(copyFont(size: size * headlineScale))
            .minimumScaleFactor(0.45)
            .lineLimit(lineLimit)
            .foregroundStyle(copyForegroundColor(palette: palette))
            .multilineTextAlignment(copyTextAlignment)
            .frame(maxWidth: .infinity, alignment: copyFrameAlignment)
            .shadow(
                color: hasImageBackground ? Color.black.opacity(0.52) : .clear,
                radius: hasImageBackground ? 8 : 0,
                x: 0,
                y: 2
            )
    }

    private func posterSubtitle(
        palette: PosterPalette,
        size: CGFloat,
        lineLimit: Int?
    ) -> some View {
        Text(poster.subtitle)
            .font(copyFont(size: size * subtitleScale))
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.62)
            .foregroundStyle(copyForegroundColor(palette: palette).opacity(hasImageBackground ? 0.84 : 0.75))
            .multilineTextAlignment(copyTextAlignment)
            .frame(maxWidth: .infinity, alignment: copyFrameAlignment)
            .shadow(
                color: hasImageBackground ? Color.black.opacity(0.42) : .clear,
                radius: hasImageBackground ? 7 : 0,
                x: 0,
                y: 2
            )
    }

    private func ctaButton(palette: PosterPalette, cornerRadius: CGFloat, fontSize: CGFloat = 18) -> some View {
        Text(poster.cta)
            .font(copyFont(size: fontSize * ctaScale))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(copyForegroundColor(palette: palette, isButtonText: true))
            .multilineTextAlignment(copyTextAlignment)
            .background(palette.accent, in: RoundedRectangle(cornerRadius: cornerRadius))
            .frame(maxWidth: .infinity, alignment: copyFrameAlignment)
            .shadow(
                color: hasImageBackground ? Color.black.opacity(0.48) : .clear,
                radius: hasImageBackground ? 10 : 0,
                x: 0,
                y: 4
            )
    }

    private func posterWatermark(palette: PosterPalette) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let markHeight = max(34, width * 0.07)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: max(5, width * 0.008)) {
                        Image(systemName: "sparkles")
                        Text("ViralForge")
                    }
                    .font(.system(size: max(14, width * 0.028), weight: .black, design: .rounded))
                    .foregroundStyle(palette.primary.opacity(0.72))
                    .padding(.horizontal, max(12, width * 0.022))
                    .frame(height: markHeight)
                    .background(.white.opacity(0.66), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.72), lineWidth: max(1, width * 0.0012))
                    }
                    .shadow(color: .black.opacity(0.08), radius: max(8, width * 0.014), x: 0, y: max(4, width * 0.008))
                    .padding(max(18, width * 0.035))
                }
            }
        }
    }
}

private struct PosterFallbackVisual: View {
    let palette: PosterPalette
    let platform: SocialPlatform

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                Circle()
                    .fill(palette.accent.opacity(0.20))
                    .frame(width: width * 0.92, height: width * 0.92)
                    .blur(radius: width * 0.15)
                    .offset(x: -width * 0.34, y: -height * 0.30)

                Circle()
                    .fill(palette.primary.opacity(platform == .douyin || platform == .tikTok ? 0.12 : 0.07))
                    .frame(width: width * 0.78, height: width * 0.78)
                    .blur(radius: width * 0.12)
                    .offset(x: width * 0.30, y: -height * 0.04)

                RoundedRectangle(cornerRadius: width * 0.07)
                    .fill(.white.opacity(platform == .douyin || platform == .tikTok ? 0.14 : 0.70))
                    .frame(width: width * 0.50, height: height * 0.34)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -width * 0.12, y: -height * 0.10)
                    .shadow(color: palette.accent.opacity(0.16), radius: width * 0.08, x: 0, y: width * 0.05)

                RoundedRectangle(cornerRadius: width * 0.08)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.accent.opacity(0.92),
                                palette.primary.opacity(platform == .douyin || platform == .tikTok ? 0.68 : 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width * 0.27, height: height * 0.38)
                    .rotationEffect(.degrees(7))
                    .offset(x: width * 0.18, y: -height * 0.04)
                    .overlay {
                        Image(systemName: fallbackIcon)
                            .font(.system(size: max(28, width * 0.12), weight: .black))
                            .foregroundStyle(.white.opacity(0.90))
                    }
                    .shadow(color: palette.accent.opacity(0.22), radius: width * 0.08, x: 0, y: width * 0.05)

                HStack(spacing: width * 0.035) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index.isMultiple(of: 2) ? palette.accent.opacity(0.70) : .white.opacity(0.72))
                            .frame(width: width * 0.035, height: height * CGFloat([0.13, 0.22, 0.16, 0.26][index]))
                    }
                }
                .rotationEffect(.degrees(18))
                .offset(x: width * 0.28, y: -height * 0.28)
            }
        }
    }

    private var fallbackIcon: String {
        switch platform {
        case .xiaohongshu, .instagram: "camera.fill"
        case .douyin, .tikTok, .youtubeShorts: "play.fill"
        case .weChat: "bubble.left.and.bubble.right.fill"
        }
    }
}

#Preview {
    NavigationStack {
        PosterEditorView(project: SampleData.projects[0])
            .environment(AppModel())
    }
}
