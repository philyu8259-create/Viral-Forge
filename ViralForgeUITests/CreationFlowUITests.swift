import XCTest
import StoreKitTest
import UIKit

final class CreationFlowUITests: XCTestCase {
    private enum HomeGenerationMode {
        case copyOnly
        case copyAndPoster

        var buttonIdentifier: String {
            switch self {
            case .copyOnly:
                return "vf.home.generationMode.copyOnly"
            case .copyAndPoster:
                return "vf.home.generationMode.copyAndPoster"
            }
        }

        var labels: [String] {
            switch self {
            case .copyOnly:
                return ["仅文案", "Copy Only"]
            case .copyAndPoster:
                return ["文案+海报", "Copy + Poster"]
            }
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppStoreIPad13ChineseScreenshotSet() throws {
        guard shouldRunAppStoreScreenshots else {
            throw XCTSkip("Set VF_RUN_APPSTORE_SCREENSHOTS=1 to capture App Store screenshots.")
        }

        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE", "VF_UI_TEST_EMPTY_LIBRARY"] + appStorePosterBackgroundArguments())
        captureAppStoreScreenshotSet(
            in: app,
            topic: "高端早 C 晚 A 护肤套装：精华、面霜和补充装组合，主打熬夜暗沉急救、上妆更服帖、7 天焕亮感。适合小红书种草和新品转化。",
            resultTimeout: 12,
            attempts: 2
        )
    }

    func testAppStoreIPad13EnglishScreenshotSet() throws {
        guard shouldRunAppStoreScreenshots else {
            throw XCTSkip("Set VF_RUN_APPSTORE_SCREENSHOTS=1 to capture App Store screenshots.")
        }

        let app = XCUIApplication()
        launch(app, appleLanguages: "(en)", appleLocale: "en_US", extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE", "VF_UI_TEST_EMPTY_LIBRARY"] + appStorePosterBackgroundArguments())
        captureAppStoreScreenshotSet(
            in: app,
            topic: "Premium skincare launch set: serum, cream, and refill pouch for dull skin, smoother makeup, and a visible glow routine. Built for product seeding and conversion-focused launch posts.",
            resultTimeout: 12,
            attempts: 2,
            posterTimeout: 45
        )
    }

    private func captureAppStoreScreenshotSet(
        in app: XCUIApplication,
        topic: String,
        resultTimeout: TimeInterval = 10,
        attempts: Int = 2,
        posterTimeout: TimeInterval = 8
    ) {
        XCTAssertTrue(app.textViews["vf.home.topicEditor"].waitForExistence(timeout: 8), app.debugDescription)
        saveScreenshot(named: "01_home.png")

        createContentPack(
            in: app,
            topic: topic,
            resultTimeout: resultTimeout,
            attempts: attempts
        )
        saveScreenshot(named: "02_result.png")

        let posterScreen = app.scrollViews["vf.poster.screen"]
        for _ in 0..<3 {
            let continuePosterButton = app.buttons["vf.result.continuePosterButton"].firstMatch
            XCTAssertTrue(continuePosterButton.waitForExistence(timeout: 8), app.debugDescription)
            XCTAssertTrue(safeTap(continuePosterButton), app.debugDescription)

            if posterScreen.waitForExistence(timeout: posterTimeout) {
                break
            }

            let retryButton = app.buttons["vf.home.generationError.retryButton"].firstMatch
            if retryButton.waitForExistence(timeout: 2) {
                _ = safeTap(retryButton)
            }

            let editPosterButton = app.buttons["vf.result.editPosterButton.bottom"].firstMatch
            if editPosterButton.waitForExistence(timeout: 1), editPosterButton.isHittable {
                _ = safeTap(editPosterButton)
            }
            if posterScreen.waitForExistence(timeout: 2) {
                break
            }
        }

        XCTAssertTrue(posterScreen.waitForExistence(timeout: 1), app.debugDescription)
        let posterPreview = app.descendants(matching: .any)["vf.poster.preview"].firstMatch
        XCTAssertTrue(posterPreview.waitForExistence(timeout: 8), app.debugDescription)
        centerPosterPreviewForAppStoreScreenshot(posterPreview, in: posterScreen)
        XCTAssertTrue(posterPreview.isHittable, app.debugDescription)
        saveScreenshot(named: "03_poster.png")

        restartAppForRemainingAppStoreScreenshots(app)
        openTemplatesFromCreate(in: app)
        saveScreenshot(named: "04_templates.png")

        tapTab(in: app, labels: ["我的", "Me"], index: 2)
        XCTAssertTrue(waitForMyTabContentToBeReady(in: app, timeout: 8), app.debugDescription)
        XCTAssertTrue(safeTap(app.buttons["vf.my.brandButton"].firstMatch), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any)["vf.brand.screen"].waitForExistence(timeout: 8), app.debugDescription)
        saveScreenshot(named: "05_brand.png")

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(waitForMyTabContentToBeReady(in: app, timeout: 8), app.debugDescription)

        XCTAssertTrue(safeTap(app.buttons["vf.my.proButton"].firstMatch), app.debugDescription)
        XCTAssertTrue(app.scrollViews["vf.paywall.screen"].waitForExistence(timeout: 8), app.debugDescription)
        saveScreenshot(named: "06_pro.png")
    }

    private func waitForMyTabContentToBeReady(in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let myScreen = app.scrollViews["vf.my.screen"].firstMatch
        let brandButton = app.buttons["vf.my.brandButton"].firstMatch
        let proButton = app.buttons["vf.my.proButton"].firstMatch
        let fallbackProfile = app.navigationBars.buttons.matching(identifier: "我的").firstMatch

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if myScreen.exists || brandButton.exists || proButton.exists || fallbackProfile.exists {
                return true
            }
            if myScreen.waitForExistence(timeout: 0.5) {
                return true
            }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)).tap()
        }
        return false
    }

    private func restartAppForRemainingAppStoreScreenshots(_ app: XCUIApplication) {
        if returnToCreateHomeIfNeeded(in: app) {
            if app.textViews["vf.home.topicEditor"].waitForExistence(timeout: 5) {
                return
            }
        }

        for attempt in 0..<2 {
            if attempt > 0, app.state != .notRunning {
                app.terminate()
            }
            app.launch()
            if app.textViews["vf.home.topicEditor"].waitForExistence(timeout: 8) {
                return
            }
            if app.state != .notRunning {
                app.terminate()
            }
        }

        XCTFail("Unable to return to create home screen after App Store screenshot progression.")
    }

    private func centerPosterPreviewForAppStoreScreenshot(_ posterPreview: XCUIElement, in posterScreen: XCUIElement) {
        let visibleFrame = posterScreen.frame
        let targetTop = max(visibleFrame.minY + visibleFrame.height * 0.08, visibleFrame.height * 0.12)
        let targetMidBottom = visibleFrame.minY + visibleFrame.height * 0.72

        for _ in 0..<8 {
            guard posterPreview.exists else {
                posterScreen.swipeUp()
                continue
            }

            let frame = posterPreview.frame
            if frame.minY >= targetTop, frame.midY <= targetMidBottom {
                return
            }

            if frame.midY > targetMidBottom {
                posterScreen.swipeUp()
            } else {
                posterScreen.swipeDown()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
    }

    private func openTemplatesFromCreate(in app: XCUIApplication) {
        _ = returnToCreateHomeIfNeeded(in: app)
        tapTab(in: app, labels: ["创作", "Create"], index: 0)

        var found = false
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            dismissTemplateInterruptions(in: app)

            if let button = templateButton(in: app) {
                XCTAssertTrue(safeTap(button), app.debugDescription)
                if app.scrollViews.firstMatch.waitForExistence(timeout: 3)
                    || app.buttons["Use Template"].waitForExistence(timeout: 1)
                    || app.buttons["套用模板"].waitForExistence(timeout: 1)
                    || app.scrollViews["vf.home.creationWorkflowTemplateList"].waitForExistence(timeout: 1) {
                    found = true
                    break
                }
            }
            if found { break }

            app.swipeUp()
        }

        XCTAssertTrue(found, app.debugDescription)

        if found {
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 8), app.debugDescription)
        }
    }

    private func templateButton(in app: XCUIApplication) -> XCUIElement? {
        let directCandidates = [
            app.buttons["套用模板"].firstMatch,
            app.buttons["Use Template"].firstMatch,
        ]

        if let candidate = directCandidates.first(where: { isUsableButton($0, in: app) }) {
            return candidate
        }

        let templateRows = app.buttons.matching(identifier: "vf.home.creationSupportRow").allElementsBoundByIndex
        if let row = templateRows.first(where: {
            isUsableButton($0, in: app)
                && ($0.label.lowercased().contains("套用模板") || $0.label.lowercased().contains("use template") || $0.label.lowercased().contains("template"))
        }) {
            return row
        }

        return templateRows.first(where: { isUsableButton($0, in: app) })
    }

    private func isUsableButton(_ button: XCUIElement, in app: XCUIApplication) -> Bool {
        button.waitForExistence(timeout: 0.3) && !button.frame.isEmpty
    }

    private func dismissTemplateInterruptions(in app: XCUIApplication) {
        let interruptionButtons = [
            app.buttons["完成"].firstMatch,
            app.buttons["Done"].firstMatch,
            app.buttons["取消"].firstMatch,
            app.buttons["Cancel"].firstMatch,
        ]

        for button in interruptionButtons {
            if button.waitForExistence(timeout: 0.1), button.isHittable {
                button.tap()
                RunLoop.current.run(until: Date().addingTimeInterval(0.15))
                return
            }
        }

        let overlay = app.otherElements["PopoverDismissRegion"].firstMatch
        if overlay.exists, overlay.frame.intersects(app.frame) {
            overlay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
    }

    private func returnToCreateHomeIfNeeded(in app: XCUIApplication) -> Bool {
        let topicEditor = app.textViews["vf.home.topicEditor"]
        if topicEditor.exists { return true }

        for _ in 0..<4 {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists, !backButton.frame.isEmpty {
                backButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                if topicEditor.waitForExistence(timeout: 2) {
                    return true
                }
            } else {
                break
            }
        }

        return topicEditor.exists
    }

    private func tapTab(in app: XCUIApplication, labels: [String], index: Int) {
        for label in labels {
            let button = app.buttons[label].firstMatch
            if button.waitForExistence(timeout: 2), button.isHittable {
                button.tap()
                return
            }
        }

        let xPositions: [CGFloat] = [0.18, 0.50, 0.82]
        let x = xPositions[min(max(index, 0), xPositions.count - 1)]
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.965)).tap()
    }

    func testMockCreationFlowNavigatesToResult() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(
            in: app,
            resultTimeout: 12,
            attempts: 2
        )

        XCTAssertTrue(app.staticTexts["标题"].waitForExistence(timeout: 4))
        assertCopyPackWorks(in: app, statusText: "整套发布稿已复制。")
        assertResultEditorSaves(in: app, statusText: "修改已保存。")
        saveScreenshot(named: "e2e-03-result.png")
    }

    func testDefaultGenerationModeCanNavigateDirectlyToPosterEditor() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(
            in: app,
            topic: "可折叠保温水杯，适合通勤与健身后补水，三小时续航保温。",
            resultTimeout: 12,
            generationMode: .copyAndPoster
        )

        XCTAssertTrue(app.scrollViews["vf.poster.screen"].waitForExistence(timeout: 12), app.debugDescription)
        XCTAssertTrue(app.buttons["vf.poster.generateBackgroundButton"].waitForExistence(timeout: 4))
    }

    func testHomeInputToolsExposeVoiceAndProductImageActions() throws {
        let app = XCUIApplication()
        launch(app)

        XCTAssertTrue(app.textViews["vf.home.topicEditor"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["vf.home.voiceInputButton"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.home.productImageButton"].waitForExistence(timeout: 4))
    }

    func testHomeTopicKeyboardCanDismissFromDoneButton() throws {
        let app = XCUIApplication()
        launch(app)

        let topicEditor = app.textViews["vf.home.topicEditor"]
        XCTAssertTrue(topicEditor.waitForExistence(timeout: 8))
        topicEditor.tap()
        topicEditor.typeText("键盘收起测试")

        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 4), app.debugDescription)
        let doneButton = app.buttons["vf.home.keyboardDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 4), app.debugDescription)
        doneButton.tap()

        let keyboardHidden = NSPredicate(format: "exists == false")
        expectation(for: keyboardHidden, evaluatedWith: app.keyboards.firstMatch)
        waitForExpectations(timeout: 4)
    }

    func testEmptyTopicGenerateShowsValidationMessage() throws {
        let app = XCUIApplication()
        launch(app)

        let generateButton = app.buttons["vf.home.generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 8))
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["vf.home.generationError"].waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(app.staticTexts["请先输入主题或产品。"].waitForExistence(timeout: 4), app.debugDescription)
    }

    func testHomePipelineProjectCardOpensResult() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(in: app)
        XCTAssertTrue(app.scrollViews["vf.result.screen"].waitForExistence(timeout: 4), app.debugDescription)

        app.navigationBars.buttons.firstMatch.tap()

        let pipelineCard = app.buttons["vf.home.pipeline.projectCard"].firstMatch
        XCTAssertTrue(pipelineCard.waitForExistence(timeout: 8), app.debugDescription)
        pipelineCard.tap()

        XCTAssertTrue(app.scrollViews["vf.result.screen"].waitForExistence(timeout: 4), app.debugDescription)
    }

    func testBottomEditPosterButtonOpensPosterEditor() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(in: app)

        let resultScreen = app.scrollViews["vf.result.screen"]
        XCTAssertTrue(resultScreen.waitForExistence(timeout: 8), app.debugDescription)

        let bottomEditButton = app.buttons["vf.result.editPosterButton.bottom"]
        for _ in 0..<8 where !bottomEditButton.isHittable {
            resultScreen.swipeUp()
        }
        XCTAssertTrue(bottomEditButton.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(bottomEditButton.isHittable, app.debugDescription)
        bottomEditButton.tap()

        XCTAssertTrue(app.scrollViews["vf.poster.screen"].waitForExistence(timeout: 8), app.debugDescription)
    }

    func testProductImagePickerAttachesPhotoToHomeBrief() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE"])

        let attachment = app.descendants(matching: .any)["vf.home.productImageAttachment"]
        XCTAssertTrue(attachment.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(app.staticTexts["vf.home.productImageSubjectStatus"].waitForExistence(timeout: 4), app.debugDescription)
    }

    func testAttachedProductImageCarriesIntoPosterEditor() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE"])

        let attachment = app.descendants(matching: .any)["vf.home.productImageAttachment"]
        XCTAssertTrue(attachment.waitForExistence(timeout: 8), app.debugDescription)
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))
        let productLockNoticeCN = app.staticTexts["已锁定真实产品，AI 背景会围绕该产品自然融合"]
        let productLockNoticeEN = app.staticTexts["Real product locked. AI backgrounds will be built around it."]
        XCTAssertTrue(productLockNoticeCN.waitForExistence(timeout: 4) || productLockNoticeEN.waitForExistence(timeout: 2), app.debugDescription)

        let productIntegrationStatus = app.staticTexts["vf.poster.productIntegrationStatus"]
        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        XCTAssertTrue(productIntegrationStatus.waitForExistence(timeout: 4), app.debugDescription)
    }

    func testPosterChannelLabelCanBeEdited() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        let labelField = app.textFields["vf.poster.channelLabelField"]
        for _ in 0..<4 where !labelField.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(labelField.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(labelField.isHittable, app.debugDescription)

        labelField.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        labelField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20))
        labelField.typeText("OFFICE PICK")

        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else {
            posterScreen.tap()
        }

        let labelBadge = app.staticTexts["vf.poster.channelLabelBadge"]
        for _ in 0..<3 where !labelBadge.exists {
            posterScreen.swipeDown()
        }
        XCTAssertTrue(labelBadge.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertEqual(labelBadge.label, "OFFICE PICK")
        saveScreenshot(named: "poster-channel-label-edited.png")
    }

    func testRegenerateBackgroundOnlyPreservesPosterCopy() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_POSTER_BACKGROUND_GENERATION"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        let generateButton = app.buttons["vf.poster.generateBackgroundButton"]
        for _ in 0..<4 where !generateButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4), app.debugDescription)
        generateButton.tap()
        XCTAssertTrue(app.staticTexts["vf.poster.backgroundStatus"].waitForExistence(timeout: 8), app.debugDescription)

        let headlineField = app.textFields["vf.poster.headlineField"]
        for _ in 0..<4 where !headlineField.isHittable {
            posterScreen.swipeDown()
        }
        XCTAssertTrue(headlineField.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(headlineField.isHittable, app.debugDescription)

        headlineField.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        headlineField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30))
        headlineField.typeText("KEEP THIS COPY")

        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else {
            posterScreen.tap()
        }

        let regenerateButton = app.buttons["vf.poster.regenerateBackgroundOnlyButton"]
        for _ in 0..<4 where !regenerateButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(regenerateButton.waitForExistence(timeout: 4), app.debugDescription)
        regenerateButton.tap()

        XCTAssertTrue(app.staticTexts["vf.poster.backgroundStatus"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertEqual(headlineField.value as? String, "KEEP THIS COPY")
    }

    func testPosterBackgroundHistoryKeepsPreviousVersionsSelectable() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_POSTER_BACKGROUND_GENERATION"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        let generateButton = app.buttons["vf.poster.generateBackgroundButton"]
        for _ in 0..<4 where !generateButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4), app.debugDescription)
        generateButton.tap()
        XCTAssertTrue(app.staticTexts["vf.poster.backgroundStatus"].waitForExistence(timeout: 8), app.debugDescription)

        let regenerateButton = app.buttons["vf.poster.regenerateBackgroundOnlyButton"]
        for _ in 0..<4 where !regenerateButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(regenerateButton.waitForExistence(timeout: 4), app.debugDescription)
        regenerateButton.tap()
        XCTAssertTrue(app.staticTexts["vf.poster.backgroundStatus"].waitForExistence(timeout: 8), app.debugDescription)

        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        let history = app.descendants(matching: .any)["vf.poster.backgroundHistory"]
        XCTAssertTrue(history.waitForExistence(timeout: 8), app.debugDescription)

        let versionButtons = app.buttons.matching(identifier: "vf.poster.backgroundVersion")
        XCTAssertGreaterThanOrEqual(versionButtons.count, 2, app.debugDescription)
        versionButtons.element(boundBy: 1).tap()

        XCTAssertTrue(app.staticTexts["vf.poster.backgroundStatus"].waitForExistence(timeout: 4), app.debugDescription)
    }

    func testPosterBackgroundDirectionCanBeSelectedBeforeGeneration() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_POSTER_BACKGROUND_GENERATION"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        let negativeSpaceButton = app.buttons["vf.poster.backgroundDirection.negativeSpace"]
        for _ in 0..<4 where !negativeSpaceButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(negativeSpaceButton.waitForExistence(timeout: 4), app.debugDescription)
        negativeSpaceButton.tap()

        let directionStatus = app.staticTexts["vf.poster.backgroundDirectionStatus"]
        XCTAssertTrue(directionStatus.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertEqual(directionStatus.label, "更强留白")

        let generateButton = app.buttons["vf.poster.generateBackgroundButton"]
        for _ in 0..<4 where !generateButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4), app.debugDescription)
        generateButton.tap()

        XCTAssertTrue(app.staticTexts["vf.poster.backgroundStatus"].waitForExistence(timeout: 8), app.debugDescription)
    }

    func testPosterBackgroundDirectionPreviewsCanBeGeneratedAndSelected() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_POSTER_BACKGROUND_GENERATION"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        let previewButton = app.buttons["vf.poster.generateDirectionPreviewsButton"]
        for _ in 0..<4 where !previewButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(previewButton.waitForExistence(timeout: 4), app.debugDescription)
        previewButton.tap()

        let previewGrid = app.descendants(matching: .any)["vf.poster.directionPreviewGrid"]
        XCTAssertTrue(previewGrid.waitForExistence(timeout: 12), app.debugDescription)

        let previewButtons = app.buttons.matching(identifier: "vf.poster.directionPreview")
        XCTAssertEqual(previewButtons.count, 4, app.debugDescription)
        previewButtons.element(boundBy: 1).tap()

        let status = app.staticTexts["vf.poster.backgroundStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 4), app.debugDescription)
    }

    func testPosterBackgroundDirectionPreviewsShowQuotaCostAndLimit() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_POSTER_BACKGROUND_GENERATION", "VF_UI_TEST_LOW_POSTER_QUOTA"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        let quotaHint = app.staticTexts["vf.poster.directionPreviewQuotaHint"]
        for _ in 0..<4 where !quotaHint.exists {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(quotaHint.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertEqual(quotaHint.label, "预计消耗 2 次 AI 背景额度")

        let previewButton = app.buttons["vf.poster.generateDirectionPreviewsButton"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(previewButton.label.contains("生成 2 张方向预览"), previewButton.label)
    }

    func testProductImageIntegrationModeCanBeSelectedInPosterEditor() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        let productLockNoticeCN = app.staticTexts["已锁定真实产品，AI 背景会围绕该产品自然融合"]
        let productLockNoticeEN = app.staticTexts["Real product locked. AI backgrounds will be built around it."]
        XCTAssertTrue(productLockNoticeCN.waitForExistence(timeout: 4) || productLockNoticeEN.waitForExistence(timeout: 2), app.debugDescription)

        let preserveButton = app.buttons["vf.poster.productIntegration.preserve"]
        for _ in 0..<4 where !preserveButton.exists {
            posterScreen.swipeUp()
        }
        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        let status = app.staticTexts["vf.poster.productIntegrationStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(preserveButton.waitForExistence(timeout: 4), app.debugDescription)
        preserveButton.tap()
        XCTAssertEqual(status.label, "严格保留外观")

        let naturalButton = app.buttons["vf.poster.productIntegration.natural"]
        XCTAssertTrue(naturalButton.waitForExistence(timeout: 4), app.debugDescription)
        naturalButton.tap()
        XCTAssertEqual(status.label, "更自然融入")
    }

    func testProductImageIntegrationDefaultsToNaturalInPosterEditor() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        let status = app.staticTexts["vf.poster.productIntegrationStatus"]
        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        XCTAssertTrue(status.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertEqual(status.label, "更自然融入")
    }

    func testPosterCopySafetyPlacementCanBeChangedWithProductImage() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE"])
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        let autoButton = app.buttons["vf.poster.textPlacement.automatic"]
        for _ in 0..<4 where !autoButton.exists {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(autoButton.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(app.buttons["vf.poster.textPlacement.top"].exists)
        XCTAssertTrue(app.buttons["vf.poster.textPlacement.bottom"].exists)

        let topButton = app.buttons["vf.poster.textPlacement.top"]
        topButton.tap()
        XCTAssertTrue(app.staticTexts["文案位置已更新。重新生成背景后，产品避让效果会更好。"].waitForExistence(timeout: 4))

        let bottomButton = app.buttons["vf.poster.textPlacement.bottom"]
        XCTAssertTrue(bottomButton.waitForExistence(timeout: 4), app.debugDescription)
        bottomButton.tap()
        saveScreenshot(named: "poster-copy-safety-placement.png")
    }

    func testLatestPosterEditorPreviewScreenshot() throws {
        let app = XCUIApplication()
        launch(app)

        openAssetsTab(in: app)

        let postersSection = app.buttons["vf.assets.section.Posters"]
        XCTAssertTrue(postersSection.waitForExistence(timeout: 8), app.debugDescription)
        postersSection.tap()

        let editButton = app.buttons["vf.assets.poster.editButton"].firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 8), app.debugDescription)
        editButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8), app.debugDescription)
        saveScreenshot(named: "latest-poster-editor-preview.png")
    }

    func testVoiceInputButtonProvidesRecordingFeedback() throws {
        let app = XCUIApplication()
        addPermissionMonitor(to: app)
        launch(app)

        let voiceButton = app.buttons["vf.home.voiceInputButton"]
        XCTAssertTrue(voiceButton.waitForExistence(timeout: 8))
        voiceButton.tap()

        let status = app.staticTexts["vf.home.inputToolStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 8), app.debugDescription)
    }

    func testPosterExportAppearsInAssets() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        let renderButton = app.buttons["vf.poster.renderButton"]
        XCTAssertTrue(renderButton.waitForExistence(timeout: 8))
        renderButton.tap()

        let exportStatus = app.staticTexts["vf.poster.exportStatus"]
        XCTAssertTrue(exportStatus.waitForExistence(timeout: 8))

        openAssetsTab(in: app)

        let postersSection = app.buttons["vf.assets.section.Posters"]
        XCTAssertTrue(postersSection.waitForExistence(timeout: 4))
        postersSection.tap()

        let posterEditButton = app.buttons["vf.assets.poster.editButton"].firstMatch
        XCTAssertTrue(posterEditButton.waitForExistence(timeout: 8))
        saveScreenshot(named: "e2e-04-assets-poster.png")
    }

    func testFreePosterExportOffersProWatermarkUpgrade() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(in: app)

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 8))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 8))

        let renderButton = app.buttons["vf.poster.renderButton"]
        XCTAssertTrue(renderButton.waitForExistence(timeout: 8))
        renderButton.tap()

        let exportStatus = app.staticTexts["vf.poster.exportStatus"]
        XCTAssertTrue(exportStatus.waitForExistence(timeout: 8))

        let noWatermarkButton = app.buttons["vf.poster.noWatermarkButton"]
        XCTAssertTrue(noWatermarkButton.waitForExistence(timeout: 4))
        noWatermarkButton.tap()

        XCTAssertTrue(app.scrollViews["vf.paywall.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any)["vf.paywall.reasonCard"].waitForExistence(timeout: 4))
    }

    func testLiveChinaBackendGeneratesPosterBackgroundAndAssets() throws {
        guard shouldRunLiveBackendUITests else {
            throw XCTSkip("Set VF_RUN_LIVE_UI_TESTS=1 or create /tmp/viralforge-run-live-ui-tests to run the paid live China backend UI flow.")
        }

        let app = XCUIApplication()
        let topic = "便携榨汁杯，适合上班族办公室快速早餐，主打便携、好清洗、低噪音、颜值高。"
        launchLiveBackend(app, extraArguments: ["VF_UI_TEST_ATTACHED_PRODUCT_IMAGE", "VF_UI_TEST_TOPIC", topic])
        XCTAssertTrue(app.descendants(matching: .any)["vf.home.productImageAttachment"].waitForExistence(timeout: 8), app.debugDescription)

        createContentPack(
            in: app,
            topic: topic,
            resultTimeout: 75,
            attempts: 2
        )

        let editPosterButton = app.buttons["vf.result.editPosterButton"].firstMatch
        XCTAssertTrue(editPosterButton.waitForExistence(timeout: 20))
        editPosterButton.tap()

        let posterScreen = app.scrollViews["vf.poster.screen"]
        XCTAssertTrue(posterScreen.waitForExistence(timeout: 20))

        openPosterAdvancedSettings(in: app, posterScreen: posterScreen)
        let productIntegrationStatus = app.staticTexts["vf.poster.productIntegrationStatus"]
        for _ in 0..<4 where !productIntegrationStatus.exists {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(productIntegrationStatus.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertEqual(productIntegrationStatus.label, "更自然融入")

        let channelLabelBadge = app.staticTexts["vf.poster.channelLabelBadge"]
        for _ in 0..<4 where !channelLabelBadge.exists {
            posterScreen.swipeDown()
        }
        XCTAssertTrue(channelLabelBadge.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertFalse(["小红书", "抖音", "微信"].contains(channelLabelBadge.label), channelLabelBadge.label)

        let backgroundButton = app.buttons["vf.poster.generateBackgroundButton"]
        for _ in 0..<4 where !backgroundButton.isHittable {
            posterScreen.swipeUp()
        }
        XCTAssertTrue(backgroundButton.waitForExistence(timeout: 10))
        backgroundButton.tap()
        waitForEnabled(backgroundButton, timeout: 120)
        XCTAssertFalse(app.descendants(matching: .any)["vf.poster.backgroundError"].exists)
        saveScreenshot(named: "e2e-live-poster-after-background.png")

        let renderButton = app.buttons["vf.poster.renderButton"]
        XCTAssertTrue(renderButton.waitForExistence(timeout: 10))
        renderButton.tap()

        let exportStatus = app.staticTexts["vf.poster.exportStatus"]
        XCTAssertTrue(exportStatus.waitForExistence(timeout: 15))

        openAssetsTab(in: app, timeout: 15)

        let postersSection = app.buttons["vf.assets.section.Posters"]
        XCTAssertTrue(postersSection.waitForExistence(timeout: 8))
        postersSection.tap()

        let posterEditButton = app.buttons["vf.assets.poster.editButton"].firstMatch
        XCTAssertTrue(posterEditButton.waitForExistence(timeout: 15))
        saveScreenshot(named: "e2e-live-china-assets-poster.png")
    }

    func testLiveBackendGenerateButtonNavigatesToResult() throws {
        guard shouldRunLiveBackendUITests else {
            throw XCTSkip("Set VF_RUN_LIVE_UI_TESTS=1 or create /tmp/viralforge-run-live-ui-tests to run the live backend UI flow.")
        }

        let app = XCUIApplication()
        let topic = "便携榨汁杯，适合上班族办公室快速早餐，主打便携、好清洗、低噪音、颜值高。"
        launchLiveBackend(app, extraArguments: ["VF_UI_TEST_TOPIC", topic])

        createContentPack(
            in: app,
            topic: topic,
            resultTimeout: 75,
            attempts: 2
        )

        XCTAssertTrue(app.scrollViews["vf.result.screen"].waitForExistence(timeout: 8), app.debugDescription)
        saveScreenshot(named: "e2e-live-backend-generate-button-result.png")
    }

    func testEnglishLocaleUsesGlobalPlatforms() throws {
        let app = XCUIApplication()
        launch(app, appleLanguages: "(en)", appleLocale: "en_US")

        XCTAssertTrue(app.staticTexts["TikTok"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Instagram"].exists)
        XCTAssertTrue(app.staticTexts["YouTube Shorts"].exists)

        createContentPack(
            in: app,
            topic: "Portable blender for busy creators, fast breakfast, easy cleanup, low noise, and camera-friendly design."
        )
        XCTAssertTrue(app.staticTexts["Titles"].waitForExistence(timeout: 4))
        assertCopyPackWorks(in: app, statusText: "Full publish pack copied.")
    }

    func testTemplateLibraryShowsWorkflowDetails() throws {
        let app = XCUIApplication()
        launch(app)

        openTemplatesFromCreate(in: app)
        XCTAssertTrue(app.staticTexts["产品种草"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["探店引流"].exists)

        let templateCard = app.buttons["vf.templateCard.小红书真实种草笔记"]
        XCTAssertTrue(templateCard.waitForExistence(timeout: 4))
        templateCard.tap()

        XCTAssertTrue(app.staticTexts["内容结构"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["适合人群"].exists)
        let applyButton = app.buttons["vf.templateDetail.applyToStudioButton"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.templateDetail.useTemplateButton"].waitForExistence(timeout: 4))
        applyButton.tap()

        XCTAssertTrue(app.textViews["vf.home.topicEditor"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["vf.home.appliedTemplateCard"].waitForExistence(timeout: 4))
    }

    func testNoQuotaShowsFriendlyError() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_NO_QUOTA"])

        let topicEditor = app.textViews["vf.home.topicEditor"]
        XCTAssertTrue(topicEditor.waitForExistence(timeout: 8))
        topicEditor.tap()
        topicEditor.typeText("便携榨汁杯，适合上班族办公室快速早餐，主打便携、好清洗、低噪音、颜值高。")
        dismissKeyboardIfNeeded(in: app)

        let generateButton = app.buttons["vf.home.generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4))
        generateButton.tap()

        XCTAssertTrue(app.scrollViews["vf.paywall.screen"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any)["vf.paywall.reasonCard"].waitForExistence(timeout: 4))
        let textQuotaReason = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "今日免费文案生成 3 次已用完")
        ).firstMatch
        XCTAssertTrue(textQuotaReason.waitForExistence(timeout: 4))
    }

    func testLockedTemplateRoutesToPaywall() throws {
        let app = XCUIApplication()
        launch(app)

        openTemplatesFromCreate(in: app)
        XCTAssertTrue(app.staticTexts["直播预热"].waitForExistence(timeout: 8))
        app.staticTexts["直播预热"].tap()

        let templateCard = app.buttons["vf.templateCard.直播间预约预热"]
        XCTAssertTrue(templateCard.waitForExistence(timeout: 4))
        templateCard.tap()

        XCTAssertTrue(app.descendants(matching: .any)["vf.templateDetail.proLockedCard"].waitForExistence(timeout: 4))
        let useButton = app.buttons["vf.templateDetail.useTemplateButton"]
        XCTAssertTrue(useButton.waitForExistence(timeout: 4))
        useButton.tap()

        XCTAssertTrue(app.scrollViews["vf.paywall.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any)["vf.paywall.reasonCard"].waitForExistence(timeout: 4))
    }

    func testEmptyAssetsShowsNextAction() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_EMPTY_LIBRARY"])

        openAssetsTab(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["vf.assets.emptyState"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["暂无项目"].waitForExistence(timeout: 4))

        let createButton = app.buttons["去创作"].firstMatch
        XCTAssertTrue(createButton.waitForExistence(timeout: 4))
        createButton.tap()
        XCTAssertTrue(app.textViews["vf.home.topicEditor"].waitForExistence(timeout: 4))
    }

    func testHomeQuotaRingShowsFriendlyText() throws {
        let app = XCUIApplication()
        launch(app)

        let freeQuotaLabel = app.staticTexts.element(
            matching: NSPredicate(format: "label BEGINSWITH[c] %@", "今日文案 ")
        )
        XCTAssertTrue(freeQuotaLabel.waitForExistence(timeout: 4), app.debugDescription)
    }

    func testProjectsOpenActionPrioritizesPosterEditing() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(
            in: app,
            resultTimeout: 12,
            attempts: 2,
            generationMode: .copyAndPoster
        )

        openAssetsTab(in: app)
        let projectPrimaryAction = app.buttons["vf.assets.project.openButton"].firstMatch
        XCTAssertTrue(projectPrimaryAction.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(projectPrimaryAction.label == "继续编辑海报" || projectPrimaryAction.label == "Continue Poster")

        projectPrimaryAction.tap()
        XCTAssertTrue(app.scrollViews["vf.poster.screen"].waitForExistence(timeout: 8), app.debugDescription)
    }

    func testAssetsExposeProjectAndSnippetSections() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(in: app)

        openAssetsTab(in: app)
        let assetsScreen = app.scrollViews["vf.assets.screen"]

        if !app.staticTexts["文案包"].waitForExistence(timeout: 2) {
            assetsScreen.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["文案包"].waitForExistence(timeout: 4))

        let snippetsSection = app.buttons["vf.assets.section.Snippets"]
        XCTAssertTrue(snippetsSection.waitForExistence(timeout: 4))
        snippetsSection.tap()

        if !app.staticTexts["标题"].waitForExistence(timeout: 2) {
            assetsScreen.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["标题"].waitForExistence(timeout: 4))
    }

    func testPaywallShowsChinaSubscriptionPlans() throws {
        let app = XCUIApplication()
        launch(app)

        openPaywallFromMe(in: app)

        XCTAssertTrue(app.scrollViews["vf.paywall.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["vf.paywall.plan.viralforge_pro_monthly"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.paywall.plan.viralforge_pro_yearly"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["¥39.8/月"].exists)
        XCTAssertTrue(app.staticTexts["¥398/年"].exists)
        XCTAssertTrue(app.buttons["vf.paywall.purchaseButton"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.paywall.restoreButton"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.paywall.privacyLink"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.paywall.termsLink"].exists)
        XCTAssertFalse(app.staticTexts["本地 StoreKit 已按中国区价格配置"].exists)
        XCTAssertFalse(app.staticTexts["后端设置"].exists)
        XCTAssertFalse(app.staticTexts["购买已接入 StoreKit。本地测试使用内置 StoreKit 配置；正式上架还需要在 App Store Connect 创建同 ID 商品。"].exists)
    }

    @MainActor
    func testLocalStoreKitPurchaseActivatesPro() async throws {
        guard shouldRunLocalStoreKitPurchaseTests else {
            throw XCTSkip("Set VF_RUN_STOREKIT_PURCHASE_TESTS=1 or create /tmp/viralforge-run-storekit-purchase-tests to run the local StoreKit purchase flow.")
        }

        let session = try localStoreKitSession()
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        do {
            try await session.buyProduct(identifier: "viralforge_pro_monthly")
        } catch {
            let message = String(describing: error)
            if message.contains("notEntitled") {
                throw XCTSkip("Current runner is not entitled for off-device StoreKitTest purchases. Use Xcode's StoreKit Transaction Manager or a sandbox account on device.")
            }
            throw error
        }

        let app = XCUIApplication()
        launch(app)

        openPaywallFromMe(in: app)
        XCTAssertTrue(app.scrollViews["vf.paywall.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["会员已开通"].waitForExistence(timeout: 12) || app.staticTexts["Pro Active"].waitForExistence(timeout: 1))
    }

    func testSettingsShowsRequiredAppStoreLinks() throws {
        let app = XCUIApplication()
        launch(app)

        openSettings(in: app)

        XCTAssertTrue(app.scrollViews["vf.settings.screen"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.settings.privacyLink"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.settings.termsLink"].exists)
        XCTAssertTrue(app.buttons["vf.settings.supportLink"].exists)
        XCTAssertFalse(app.buttons["vf.settings.emailSupportLink"].exists)
        XCTAssertFalse(app.buttons["vf.settings.dataDeletionLink"].exists)
        XCTAssertTrue(app.buttons["vf.settings.clearLocalDataButton"].exists)
        XCTAssertTrue(app.buttons["vf.settings.restorePurchasesButton"].exists)
        XCTAssertTrue(app.staticTexts["版本"].exists)
    }

    func testClearLocalWorkspaceDataShowsConfirmation() throws {
        let app = XCUIApplication()
        launch(app)

        openSettings(in: app)

        let clearButton = app.buttons["vf.settings.clearLocalDataButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 4))
        clearButton.tap()

        let alert = app.alerts["清空本机数据？"]
        XCTAssertTrue(alert.waitForExistence(timeout: 4))
        alert.buttons["清空"].tap()

        XCTAssertTrue(app.staticTexts["vf.settings.localDataStatus"].waitForExistence(timeout: 4))
    }

    private func launch(
        _ app: XCUIApplication,
        appleLanguages: String = "(zh-Hans)",
        appleLocale: String = "zh_CN",
        extraArguments: [String] = []
    ) {
        app.launchArguments = [
            "VF_UI_TESTING",
            "-AppleLanguages", appleLanguages,
            "-AppleLocale", appleLocale
        ] + extraArguments
        app.launch()
    }

    private func addPermissionMonitor(to app: XCUIApplication) {
        addUIInterruptionMonitor(withDescription: "System permission prompts") { alert in
            for label in ["允许", "好", "继续", "Allow", "OK", "Continue"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    private func launchLiveBackend(
        _ app: XCUIApplication,
        appleLanguages: String = "(zh-Hans)",
        appleLocale: String = "zh_CN",
        extraArguments: [String] = []
    ) {
        app.launchEnvironment["VF_LIVE_BACKEND_URL"] = liveBackendURL
        app.launchEnvironment["VF_LIVE_BACKEND_USER_ID"] = liveBackendUserID
        app.launchArguments = [
            "VF_UI_TESTING",
            "VF_LIVE_BACKEND_TESTING",
            "-AppleLanguages", appleLanguages,
            "-AppleLocale", appleLocale
        ] + extraArguments
        app.launch()
    }

    private var shouldRunLiveBackendUITests: Bool {
        ProcessInfo.processInfo.environment["VF_RUN_LIVE_UI_TESTS"] == "1"
            || FileManager.default.fileExists(atPath: "/tmp/viralforge-run-live-ui-tests")
    }

    private var shouldRunLocalStoreKitPurchaseTests: Bool {
        ProcessInfo.processInfo.environment["VF_RUN_STOREKIT_PURCHASE_TESTS"] == "1"
            || FileManager.default.fileExists(atPath: "/tmp/viralforge-run-storekit-purchase-tests")
    }

    private var shouldRunAppStoreScreenshots: Bool {
        ProcessInfo.processInfo.environment["VF_RUN_APPSTORE_SCREENSHOTS"] == "1"
            || FileManager.default.fileExists(atPath: "/tmp/viralforge-run-appstore-screenshots")
    }

    private var liveBackendURL: String {
        if let value = ProcessInfo.processInfo.environment["VF_LIVE_BACKEND_URL"], !value.isEmpty {
            return value
        }
        if let value = try? String(contentsOfFile: "/tmp/viralforge-live-backend-url", encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return "http://127.0.0.1:8787"
    }

    private var liveBackendUserID: String {
        if let value = ProcessInfo.processInfo.environment["VF_LIVE_BACKEND_USER_ID"], !value.isEmpty {
            return value
        }
        return "live-ui-\(UUID().uuidString)"
    }

    private func createContentPack(
        in app: XCUIApplication,
        topic: String = "便携榨汁杯，适合上班族办公室快速早餐，主打便携、好清洗、低噪音、颜值高。",
        resultTimeout: TimeInterval = 8,
        attempts: Int = 1,
        generationMode: HomeGenerationMode = .copyOnly
    ) {
        let topicEditor = app.textViews["vf.home.topicEditor"]
        XCTAssertTrue(topicEditor.waitForExistence(timeout: 8))
        enterTopic(topic, in: topicEditor, app: app)

        dismissKeyboardIfNeeded(in: app)
        selectGenerationMode(generationMode, in: app)

        let generateButton = app.buttons["vf.home.generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4))
        XCTAssertTrue(generateButton.isEnabled)

        let destination = generationMode == .copyOnly
            ? app.scrollViews["vf.result.screen"]
            : app.scrollViews["vf.poster.screen"]

        for attempt in 1...attempts {
            generateButton.tap()
            if destination.waitForExistence(timeout: resultTimeout) {
                return
            }

            let retryButton = app.buttons["vf.home.generationError.retryButton"]
            if retryButton.waitForExistence(timeout: 2), attempt < attempts {
                retryButton.tap()
                if destination.waitForExistence(timeout: resultTimeout) {
                    return
                }
            }

            if attempt < attempts,
               generateButton.waitForExistence(timeout: 2),
               generateButton.isEnabled {
                continue
            }
        }

        let expectedScreenName = generationMode == .copyOnly ? "Result screen" : "Poster screen"
        XCTFail("\(expectedScreenName) did not appear after \(attempts) generation attempt(s).")
    }

    private func enterTopic(_ topic: String, in topicEditor: XCUIElement, app: XCUIApplication) {
        guard !topicEditorHasUserText(topicEditor) else { return }

        UIPasteboard.general.string = topic
        topicEditor.tap()
        app.typeKey("v", modifierFlags: .command)

        guard !topicEditorHasUserText(topicEditor) else { return }

        // Chinese text entry can occasionally no-op in Simulator UI tests with hardware keyboard state.
        // Use an ASCII fallback so flow tests keep exercising generation/navigation instead of keyboard input.
        UIPasteboard.general.string = "premium glow skincare launch set with serum, cream, and refill pouch for dull skin and smoother makeup."
        topicEditor.tap()
        app.typeKey("v", modifierFlags: .command)
    }

    private func topicEditorHasUserText(_ topicEditor: XCUIElement) -> Bool {
        guard let value = topicEditor.value as? String else { return false }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return false }
        return !trimmedValue.contains("输入你的产品核心点")
            && !trimmedValue.contains("Enter your product")
    }

    private func selectGenerationMode(_ mode: HomeGenerationMode, in app: XCUIApplication) {
        for _ in 0..<4 {
            for label in mode.labels {
                let fallbackButton = app.buttons[label].firstMatch
                if safeTap(fallbackButton) {
                    return
                }
            }

            let generationButton = app.buttons[mode.buttonIdentifier]
            if generationButton.waitForExistence(timeout: 1), generationButton.isHittable {
                generationButton.tap()
                return
            }

            app.swipeUp()
        }

        for label in mode.labels {
            let fallbackButton = app.buttons[label].firstMatch
            if safeTap(fallbackButton) {
                return
            }
        }
    }

    private func safeTap(_ element: XCUIElement) -> Bool {
        guard element.waitForExistence(timeout: 1), !element.frame.isEmpty else {
            return false
        }

        if element.isHittable {
            element.tap()
            return true
        }

        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return true
    }

    private func dismissKeyboardIfNeeded(in app: XCUIApplication) {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.waitForExistence(timeout: 1) else { return }

        let doneButton = app.buttons["vf.home.keyboardDoneButton"]
        if doneButton.waitForExistence(timeout: 1), !doneButton.frame.isEmpty {
            doneButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if keyboard.waitForNonExistence(timeout: 1) {
                return
            }
        }

        let hideKeyboardButton = app.keyboards.buttons["Hide keyboard"].firstMatch
        if hideKeyboardButton.waitForExistence(timeout: 1), !hideKeyboardButton.frame.isEmpty {
            hideKeyboardButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if keyboard.waitForNonExistence(timeout: 1) {
                return
            }
        }

        let keyboardDoneButton = app.keyboards.buttons["Done"].firstMatch
        if keyboardDoneButton.waitForExistence(timeout: 1), !keyboardDoneButton.frame.isEmpty {
            keyboardDoneButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if keyboard.waitForNonExistence(timeout: 1) {
                return
            }
        }

        let fallbackDoneButton = app.buttons["Done"].firstMatch
        if fallbackDoneButton.waitForExistence(timeout: 1), !fallbackDoneButton.frame.isEmpty {
            fallbackDoneButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if keyboard.waitForNonExistence(timeout: 1) {
                return
            }
        }

        let localizedDoneButton = app.buttons["完成"].firstMatch
        if localizedDoneButton.waitForExistence(timeout: 1), !localizedDoneButton.frame.isEmpty {
            localizedDoneButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if keyboard.waitForNonExistence(timeout: 1) {
                return
            }
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        if keyboard.waitForNonExistence(timeout: 1) {
            return
        }

        app.swipeDown()
    }

    private func attachFirstProductPhoto(in app: XCUIApplication) {
        let productImageButton = app.buttons["vf.home.productImageButton"]
        XCTAssertTrue(productImageButton.waitForExistence(timeout: 8))
        productImageButton.tap()

        let photosGridImage = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        XCTAssertTrue(photosGridImage.waitForExistence(timeout: 8), app.debugDescription)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.39)).tap()
    }

    private func openSettings(in app: XCUIApplication) {
        tapTab(in: app, labels: ["我的", "Me"], index: 2)
        XCTAssertTrue(app.buttons["vf.my.settingsButton"].waitForExistence(timeout: 8))
        app.buttons["vf.my.settingsButton"].tap()
    }

    private func openAssetsTab(in app: XCUIApplication, timeout: TimeInterval = 8) {
        let assetsScreen = app.scrollViews["vf.assets.screen"]
        tapTab(in: app, labels: ["项目", "Projects"], index: 1)
        if assetsScreen.waitForExistence(timeout: timeout) {
            return
        }

        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
        tapTab(in: app, labels: ["项目", "Projects"], index: 1)
        XCTAssertTrue(assetsScreen.waitForExistence(timeout: timeout))
    }

    private func openPaywallFromMe(in app: XCUIApplication) {
        tapTab(in: app, labels: ["我的", "Me"], index: 2)
        XCTAssertTrue(app.buttons["vf.my.proButton"].waitForExistence(timeout: 8), app.debugDescription)
        app.buttons["vf.my.proButton"].tap()
    }

    private func openPosterAdvancedSettings(in app: XCUIApplication, posterScreen: XCUIElement) {
        let advancedButton = app.buttons["vf.poster.advancedSettings"]
        let hasAdvancedContent = app.descendants(matching: .any)["vf.poster.productIntegrationStatus"].exists
            || app.descendants(matching: .any)["vf.poster.textPlacement.automatic"].exists
            || app.descendants(matching: .any)["vf.poster.backgroundDirectionStatus"].exists
            || app.descendants(matching: .any)["vf.poster.directionPreviewGrid"].exists
            || app.descendants(matching: .any)["vf.poster.backgroundHistory"].exists

        guard advancedButton.exists, !hasAdvancedContent else { return }
        for _ in 0..<3 {
            if advancedButton.isHittable {
                break
            }
            posterScreen.swipeUp()
        }
        if advancedButton.isHittable {
            advancedButton.tap()
        }
    }

    private func assertCopyPackWorks(in app: XCUIApplication, statusText: String) {
        let copyPackButton = app.buttons["vf.result.copyPackButton"]
        XCTAssertTrue(copyPackButton.waitForExistence(timeout: 4))
        copyPackButton.tap()

        let statusElement = app.descendants(matching: .any)["vf.result.copyStatusMessage"]
        if !statusElement.waitForExistence(timeout: 4) {
            XCTAssertTrue(app.staticTexts[statusText].waitForExistence(timeout: 2))
        }
    }

    private func assertResultEditorSaves(in app: XCUIApplication, statusText: String) {
        let editCopyButton = app.buttons["vf.result.editCopyButton"]
        XCTAssertTrue(editCopyButton.waitForExistence(timeout: 4))
        editCopyButton.tap()

        let saveButton = app.buttons["vf.resultEditor.saveButton"]
        if saveButton.waitForExistence(timeout: 4) {
            saveButton.tap()
        } else {
            let chineseSaveButton = app.buttons["保存"]
            if chineseSaveButton.waitForExistence(timeout: 2) {
                chineseSaveButton.tap()
            } else {
                let englishSaveButton = app.buttons["Save"]
                XCTAssertTrue(englishSaveButton.waitForExistence(timeout: 2))
                englishSaveButton.tap()
            }
        }

        XCTAssertTrue(app.staticTexts[statusText].waitForExistence(timeout: 4))
    }

    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "enabled == true")
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }

    private func localStoreKitSession() throws -> SKTestSession {
        let storeKitURL = projectRootURL().appendingPathComponent("ViralForge.storekit")
        return try SKTestSession(contentsOf: storeKitURL)
    }

    private func projectRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func appStorePosterBackgroundArguments() -> [String] {
        let backgroundPath = projectRootURL()
            .appendingPathComponent("artifacts/app_store_seedream/premium_skincare_conversion_hero_ui.jpg")
            .path
        return ["VF_UI_TEST_APPSTORE_POSTER_BACKGROUND_PATH=\(backgroundPath)"]
    }

    private func saveScreenshot(named fileName: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = fileName
        attachment.lifetime = .keepAlways
        add(attachment)

        let fallbackScreenshotDir = try? String(contentsOfFile: "/tmp/viralforge-e2e-screenshot-dir", encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let screenshotDir = ProcessInfo.processInfo.environment["VF_E2E_SCREENSHOT_DIR"] ?? fallbackScreenshotDir,
              !screenshotDir.isEmpty
        else { return }

        let directoryURL: URL
        if screenshotDir.hasPrefix("/") {
            directoryURL = URL(fileURLWithPath: screenshotDir, isDirectory: true)
        } else {
            directoryURL = projectRootURL().appendingPathComponent(screenshotDir, isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try? screenshot.pngRepresentation.write(to: fileURL)
    }

}
