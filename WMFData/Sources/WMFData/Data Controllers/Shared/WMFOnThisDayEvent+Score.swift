import Foundation

public extension WMFOnThisDayEvent {

    /// A score that ranks the events of one day. The feed shows the event with the highest score first.
    ///
    /// Events with more images score higher. On English Wikipedia, events about death and violence score lower.
    /// - Parameter languageCode: The language code of the wiki that returned the event.
    func score(languageCode: String?) -> Double {
        let imageCount = pages.filter { $0.originalImage != nil || $0.thumbnail != nil }.count
        return WMFOnThisDayEvent.score(text: text, imageCount: imageCount, languageCode: languageCode)
    }

    /// Compute the score from the event text and the number of images.
    ///
    /// Outside English Wikipedia the score is the image count. On English Wikipedia each image counts 0.2
    /// and each word about death or violence subtracts 1.
    static func score(text: String?, imageCount: Int, languageCode: String?) -> Double {
        guard languageCode == "en" else {
            return Double(imageCount)
        }
        let deathScore = deathMatchCount(in: text)
        return Double(imageCount) * 0.2 - Double(deathScore)
    }

    /// Events with these words still appear in the full list. The regex only makes the featured event less grim.
    private static let englishDeathRegex = try? NSRegularExpression(
        pattern: "\\b(kill(s|ed|ers|ing)?|explosion(s)?|bomb(s|ers|ing|ings|ed)?|slaughter(s|ed|ing)?|massacre(d)?|die|dead|death(s)?|attack(ing|ers|ed)?|assassin(s|ated|ation)?|murder(s|ing|ers|ed)?|execute|execut(ed|ing|ion|ions)?|terror(ist|ism|ize|izing)?|fatal(ity|ly)?)\\b",
        options: .caseInsensitive
    )

    static func deathMatchCount(in text: String?) -> Int {
        guard let text, let regex = englishDeathRegex else {
            return 0
        }
        return regex.numberOfMatches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
    }
}
