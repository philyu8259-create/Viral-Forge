import Foundation

enum AppText {
    static var isChinese: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
    }

    static func localized(_ english: String, _ chinese: String) -> String {
        isChinese ? chinese : english
    }
}
