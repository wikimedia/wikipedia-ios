import Foundation
import Testing
@testable import WMFComponents
@testable import WMFData

@Suite
struct WMFArticleDisplayTitleTests {

    private let taiwanProject = WMFProject.wikipedia(WMFLanguage(languageCode: "zh", languageVariantCode: "zh-Hant-TW"))

    @Test
    func showsTheSummaryTitleInTheLanguageVariant() {
        let displayTitle = WMFArticleDisplayTitle.displayTitle(
            title: "兰香如故",
            summaryDisplayTitle: "<span lang=\"zh-Hant-TW\" dir=\"ltr\"><span class=\"mw-page-title-main\">蘭香如故</span></span>",
            project: taiwanProject)

        #expect(displayTitle == "蘭香如故")
    }

    @Test
    func keepsTheTitleWithoutASummaryTitle() {
        #expect(WMFArticleDisplayTitle.displayTitle(title: "兰香如故", summaryDisplayTitle: nil, project: taiwanProject) == "兰香如故")
        #expect(WMFArticleDisplayTitle.displayTitle(title: "兰香如故", summaryDisplayTitle: "<span></span>", project: taiwanProject) == "兰香如故")
    }

    @Test(arguments: ["en", "de"])
    func keepsTheTitleForLanguagesWithoutVariants(languageCode: String) {
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: nil))

        #expect(WMFArticleDisplayTitle.displayTitle(title: "IPhone", summaryDisplayTitle: "iPhone", project: project) == "IPhone")
        #expect(WMFArticleDisplayTitle.displayTitle(title: "Homo sapiens", summaryDisplayTitle: "<i>Homo sapiens</i>", project: project) == "Homo sapiens")
    }
}
