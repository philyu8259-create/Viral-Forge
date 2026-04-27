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

    private func launch(_ app: XCUIApplication, appleLanguages: String = "(zh-Hans)", appleLocale: String = "zh_CN") {
        app.launchArguments = [
            "VF_UI_TESTING",
            "-AppleLanguages", appleLanguages,
            "-AppleLocale", appleLocale
        ]
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
        XCTAssertTrue(app.staticTexts[statusText].waitForExistence(timeout: 4))
    }

    private func assertResultEditorSaves(in app: XCUIApplication, statusText: String) {
        let editCopyButton = app.buttons["vf.result.editCopyButton"]
        XCTAssertTrue(editCopyButton.waitForExistence(timeout: 4))
        editCopyButton.tap()

        let saveButton = app.buttons["vf.resultEditor.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 4))
        saveButton.tap()

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
