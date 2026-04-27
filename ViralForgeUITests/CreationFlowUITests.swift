import XCTest

final class CreationFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMockCreationFlowNavigatesToResult() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "VF_UI_TESTING",
            "-AppleLanguages", "(zh-Hans)",
            "-AppleLocale", "zh_CN"
        ]
        app.launch()

        let topicEditor = app.textViews["vf.home.topicEditor"]
        XCTAssertTrue(topicEditor.waitForExistence(timeout: 8))
        topicEditor.tap()
        topicEditor.typeText("便携榨汁杯，适合上班族办公室快速早餐，主打便携、好清洗、低噪音、颜值高。")

        let generateButton = app.buttons["vf.home.generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 4))
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

        let resultScreen = app.scrollViews["vf.result.screen"]
        XCTAssertTrue(resultScreen.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["标题"].waitForExistence(timeout: 4))
        saveScreenshot(named: "e2e-03-result.png")
    }

    private func saveScreenshot(named fileName: String) {
        guard let screenshotDir = ProcessInfo.processInfo.environment["VF_E2E_SCREENSHOT_DIR"] else { return }

        let directoryURL = URL(fileURLWithPath: screenshotDir, isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: fileURL)
    }
}
