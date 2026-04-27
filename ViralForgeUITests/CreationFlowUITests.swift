import XCTest

final class CreationFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMockCreationFlowNavigatesToResult() throws {
        let app = XCUIApplication()
        launch(app)
        createContentPack(in: app)

        XCTAssertTrue(app.staticTexts["标题"].waitForExistence(timeout: 4))
        assertCopyPackWorks(in: app, statusText: "整套发布稿已复制。")
        assertResultEditorSaves(in: app, statusText: "修改已保存。")
        saveScreenshot(named: "e2e-03-result.png")
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

        app.tabBars.buttons["素材"].tap()
        XCTAssertTrue(app.scrollViews["vf.assets.screen"].waitForExistence(timeout: 8))

        let postersSection = app.buttons["vf.assets.section.Posters"]
        XCTAssertTrue(postersSection.waitForExistence(timeout: 4))
        postersSection.tap()

        let posterCard = app.buttons["vf.assets.posterCard"].firstMatch
        XCTAssertTrue(posterCard.waitForExistence(timeout: 8))
        saveScreenshot(named: "e2e-04-assets-poster.png")
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

        app.tabBars.buttons["模板"].tap()
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

        let generateButton = app.buttons["vf.home.generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4))
        generateButton.tap()

        let errorCard = app.descendants(matching: .any)["vf.home.generationError"]
        XCTAssertTrue(errorCard.waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["今日免费文案额度已用完。"].exists)
    }

    func testEmptyAssetsShowsNextAction() throws {
        let app = XCUIApplication()
        launch(app, extraArguments: ["VF_UI_TEST_EMPTY_LIBRARY"])

        app.tabBars.buttons["素材"].tap()
        XCTAssertTrue(app.scrollViews["vf.assets.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any)["vf.assets.emptyState"].waitForExistence(timeout: 4))

        let createButton = app.buttons["去创作"].firstMatch
        XCTAssertTrue(createButton.waitForExistence(timeout: 4))
        createButton.tap()
        XCTAssertTrue(app.textViews["vf.home.topicEditor"].waitForExistence(timeout: 4))
    }

    func testPaywallShowsChinaSubscriptionPlans() throws {
        let app = XCUIApplication()
        launch(app)

        app.tabBars.buttons["会员"].tap()

        XCTAssertTrue(app.staticTexts["ViralForge Pro"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["vf.paywall.plan.viralforge_pro_monthly"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.paywall.plan.viralforge_pro_yearly"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["¥39.8/月"].exists)
        XCTAssertTrue(app.staticTexts["¥398/年"].exists)
        XCTAssertTrue(app.buttons["vf.paywall.purchaseButton"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.paywall.restoreButton"].waitForExistence(timeout: 4))
    }

    func testSettingsShowsRequiredAppStoreLinks() throws {
        let app = XCUIApplication()
        launch(app)

        app.tabBars.buttons["品牌"].tap()
        XCTAssertTrue(app.buttons["vf.brand.settingsLink"].waitForExistence(timeout: 8))
        app.buttons["vf.brand.settingsLink"].tap()

        XCTAssertTrue(app.scrollViews["vf.settings.screen"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.settings.privacyLink"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["vf.settings.termsLink"].exists)
        XCTAssertTrue(app.buttons["vf.settings.supportLink"].exists)
        XCTAssertTrue(app.buttons["vf.settings.emailSupportLink"].exists)
        XCTAssertTrue(app.buttons["vf.settings.dataDeletionLink"].exists)
        XCTAssertTrue(app.buttons["vf.settings.restorePurchasesButton"].exists)
        XCTAssertTrue(app.staticTexts["版本"].exists)
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

    private func createContentPack(
        in app: XCUIApplication,
        topic: String = "便携榨汁杯，适合上班族办公室快速早餐，主打便携、好清洗、低噪音、颜值高。"
    ) {
        let topicEditor = app.textViews["vf.home.topicEditor"]
        XCTAssertTrue(topicEditor.waitForExistence(timeout: 8))
        topicEditor.tap()
        topicEditor.typeText(topic)

        let generateButton = app.buttons["vf.home.generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4))
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

        let resultScreen = app.scrollViews["vf.result.screen"]
        XCTAssertTrue(resultScreen.waitForExistence(timeout: 8))
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

    private func saveScreenshot(named fileName: String) {
        guard let screenshotDir = ProcessInfo.processInfo.environment["VF_E2E_SCREENSHOT_DIR"] else { return }

        let directoryURL = URL(fileURLWithPath: screenshotDir, isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: fileURL)
    }
}
