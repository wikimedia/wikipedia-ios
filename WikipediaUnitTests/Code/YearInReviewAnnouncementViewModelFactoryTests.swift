import Foundation
import Testing
import WMFComponents
import WMFData
import WMFNativeLocalizations
@testable import Wikipedia

@MainActor
private final class AnnouncementDelegateStub: WMFYearInReviewAnnouncementDelegate {
    func yearInReviewAnnouncementDidTapExplore() {}
    func yearInReviewAnnouncementDidTapClose() {}
    func yearInReviewAnnouncementDidTapLearnMore() {}
    func yearInReviewAnnouncementDidTapAboutInsights() {}
    func yearInReviewAnnouncementDidTapShareFeedback() {}
}

@MainActor
@Suite
struct YearInReviewAnnouncementViewModelFactoryTests {

    private typealias Factory = YearInReviewAnnouncementViewModelFactory

    private let factory = Factory()
    private let delegate = AnnouncementDelegateStub()

    private static func textByPath(_ viewModel: WMFYearInReviewAnnouncementViewModel) -> [String: String] {
        Dictionary(uniqueKeysWithValues: viewModel.riveText.map { ($0.key.path, $0.value) })
    }

    // MARK: - Copy

    /// The cover uses the intro copy of the slides, so there is one set of strings to translate.
    @Test
    func dataRichUsesTheIntroCopyWithTheDayCount() {
        let strings = factory.makeLocalizedStrings(userDataState: .dataRich, readingDayCount: 5)

        #expect(strings.animationAccessibilityLabel == CommonStrings.yearInReviewIntroTitle)
        #expect(strings.body == CommonStrings.yearInReviewIntroSubtitle(dayCount: 5))
        #expect(strings.body.contains("5"))
    }

    @Test
    func lowDataUsesTheCollectiveIntroCopy() {
        let strings = factory.makeLocalizedStrings(userDataState: .lowData, readingDayCount: 5)

        #expect(strings.animationAccessibilityLabel == CommonStrings.yearInReviewCollectiveIntroTitle)
        #expect(strings.body == CommonStrings.yearInReviewCollectiveIntroSubtitle)
    }

    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func theMoreMenuMatchesTheSlides(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let strings = factory.makeLocalizedStrings(userDataState: userDataState, readingDayCount: 1)
        let slideStrings = YearInReviewSlideViewModelFactory().makeLocalizedStrings()

        #expect(strings.learnMoreButtonTitle == slideStrings.learnMoreButtonTitle)
        #expect(strings.aboutInsightsButtonTitle == slideStrings.aboutInsightsButtonTitle)
        #expect(strings.shareFeedbackButtonTitle == slideStrings.shareFeedbackButtonTitle)
        #expect(strings.exploreButtonTitle.isEmpty == false)
    }

    @Test
    func theLoginPromptCopyDependsOnTheDataState() {
        let dataRich = factory.makeLoginPromptCopy(userDataState: .dataRich)
        let lowData = factory.makeLoginPromptCopy(userDataState: .lowData)

        #expect(dataRich.title.isEmpty == false)
        #expect(dataRich.message.isEmpty == false)
        #expect(lowData.title == CommonStrings.yearInReviewLoginPromptCollectiveTitle)
        #expect(lowData.message == CommonStrings.yearInReviewLoginPromptCollectiveMessage)
        #expect(dataRich.title != lowData.title)
    }

    // MARK: - Rive

    @Test
    func theAnnouncementUsesTheCoverOfTheTemplatesFile() {
        let viewModel = factory.makeViewModel(userDataState: .dataRich, readingDayCount: 3, delegate: delegate)

        #expect(viewModel.animation.resourceName == "all_templates")
        #expect(viewModel.animation.artboardName == "cover")
        #expect(viewModel.animation.stateMachineName == "cover-statemachine")
    }

    /// A Rive text run that the app does not write keeps the copy inside the .riv, and nothing on
    /// the screen shows it. So the cover writes both of its runs, with the text VoiceOver reads.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func theCoverWritesTheTitleAndTheBody(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let viewModel = factory.makeViewModel(userDataState: userDataState, readingDayCount: 3, delegate: delegate)
        let text = Self.textByPath(viewModel)

        #expect(Set(text.keys) == ["coverTitle", "bodyCopy"])
        #expect(text["coverTitle"] == viewModel.localizedStrings.animationAccessibilityLabel.localizedUppercase)
        #expect(text["bodyCopy"] == viewModel.localizedStrings.body)
    }

    /// Same as the slides: the .riv decides the color of the controls above it.
    @Test
    func theCoverReadsTheLightContentFlag() {
        let viewModel = factory.makeViewModel(userDataState: .dataRich, readingDayCount: 3, delegate: delegate)

        #expect(viewModel.lightContentFlag?.path == "isUIWhite")
    }

    /// Same rules as the copy on the slides: both runs are fitted, they shrink together, and never
    /// below the minimum scale of the slides.
    @Test
    func theTitleAndTheBodyAreFittedTogether() {
        let viewModel = factory.makeViewModel(userDataState: .dataRich, readingDayCount: 3, delegate: delegate)
        let fits = viewModel.textFits

        #expect(Set(fits.map(\.text.path)) == ["coverTitle", "bodyCopy"])
        #expect(Set(fits.compactMap(\.group)).count == 1)
        #expect(fits.allSatisfy { $0.group != nil })
        #expect(fits.allSatisfy { $0.minimumScale == YearInReviewSlideViewModelFactory.copyMinimumScale })
        #expect(fits.allSatisfy { $0.globalViewModelName == "GlobalProperties" })

        // Every fitted run is a run that the cover writes, so there is text to measure.
        let written = Set(Self.textByPath(viewModel).keys)
        #expect(fits.allSatisfy { written.contains($0.text.path) })
    }

    /// The app can measure only the fonts that it supplies to Rive. A fit for any other font does nothing.
    @Test
    func theFitsUseFontsThatTheAppSupplies() {
        let supplied: Set<String> = ["SanSerifFont", "SerifFont"]
        #expect(Factory.textFits.allSatisfy { supplied.contains($0.fontAssetName) })
    }

    /// A name that is not in the .riv does nothing, and Rive reports no error. So each name that the
    /// cover uses must be in the bundled file. This fails when a new export renames one.
    @Test
    func everyNameTheCoverUsesIsInTheRiveFile() throws {
        let data = try #require(Self.templatesFileData())
        let viewModel = factory.makeViewModel(userDataState: .dataRich, readingDayCount: 3, delegate: delegate)

        var names: [String] = [
            viewModel.animation.artboardName,
            viewModel.animation.stateMachineName,
            viewModel.lightContentFlag?.path
        ].compactMap { $0 }
        names += viewModel.riveText.keys.map(\.path)
        for fit in viewModel.textFits {
            names += [fit.globalViewModelName, fit.fontSize.path, fit.lineHeight.path, fit.fontAssetName]
        }

        for name in names {
            #expect(data.range(of: Data(name.utf8)) != nil, "\(name) is not in all_templates.riv")
        }
    }

    /// The .riv is a resource of the WMFComponents package, in its own bundle inside the app.
    private static func templatesFileData() -> Data? {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: nil) else {
            return nil
        }
        for case let url as URL in enumerator where url.lastPathComponent == "all_templates.riv" {
            return try? Data(contentsOf: url)
        }
        return nil
    }
}
