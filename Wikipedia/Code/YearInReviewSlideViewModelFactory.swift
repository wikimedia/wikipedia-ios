import Foundation
import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Makes the content that the Year in Review view model is built from.
struct YearInReviewSlideViewModelFactory {

    func makeLocalizedStrings() -> WMFYearInReviewViewModel.LocalizedStrings {
        WMFYearInReviewViewModel.LocalizedStrings(
            wIconAccessibilityLabel: "Wikipedia",
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            moreButtonAccessibilityLabel: "More",
            shareButtonTitle: CommonStrings.shortShareTitle,
            donateButtonTitle: CommonStrings.donateTitle,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle,
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    func makeSlides() -> [WMFYearInReviewSlideViewModel] {
        // TEMPORARY: mock slides driven from the one sample .riv. The sentences are hardcoded
        // stand-ins for WMFLocalizedString, including the Arabic and Chinese ones, so the split
        // can be seen working in a right-to-left script and in one with no spaces.
        let frame1 = "frame1"
        let frame2 = "frame2"
        let stateMachine = "insightFrame-stateMachine"

        let headline1 = WMFRiveText(path: "headline1")
        let headline2 = WMFRiveText(path: "headline2")
        let bodyCopy = WMFRiveText(path: "bodyCopy")
        let readDays = WMFRiveText(path: "readDays")
        let streakNumber = WMFRiveText(path: "streakNumber")

        /// One sentence, one variable, spread across the three runs that draw it.
        func slide(
            id: String,
            artboard: String,
            sentence: String,
            value: String,
            numberPath: WMFRiveText,
            body: String,
            accessibilityLabel: String,
            showsShareButton: Bool = true
        ) -> WMFYearInReviewSlideViewModel {
            var text = WMFRiveSentence(
                format: sentence,
                value: value,
                leading: headline1,
                middle: numberPath,
                trailing: headline2
            ).text
            text[bodyCopy] = body

            return WMFYearInReviewSlideViewModel(
                id: id,
                loggingID: id,
                animation: WMFRiveAnimation(resourceName: riveResourceName, artboardName: artboard, stateMachineName: stateMachine),
                text: text,
                localizedStrings: .init(accessibilityLabel: accessibilityLabel),
                showsShareButton: showsShareButton,
                contentStyle: .dark
            )
        }

        return [
            slide(
                id: "readCount",
                artboard: frame1,
                sentence: "In 2026, you read Wikipedia on %1$@ days.",
                value: "47", // this will be a variable from user data cast as string
                numberPath: readDays,
                body: "That puts you in the top 5% of readers on English Wikipedia this year.",
                accessibilityLabel: "In 2026, you read Wikipedia on 47 days.", // this will have the value from the user data interpolated
                showsShareButton: false
            ),
            slide(
                id: "streak",
                artboard: frame2,
                sentence: "Your longest streak was %1$@ days in a row.",
                value: "31",
                numberPath: streakNumber,
                body: "From 4 to 14 March.",
                accessibilityLabel: "Your longest streak was 31 days in a row."
            ),
            slide(
                id: "minutesRead",
                artboard: frame1,
                sentence: "You spent %1$@ minutes reading this year.",
                value: "924",
                numberPath: readDays,
                body: "Mostly on Wednesday evenings, going by your reading history.",
                accessibilityLabel: "You spent 924 minutes reading this year."
            ),
            // The placeholder sits late in the sentence and the script runs right to left.
            slide(
                id: "arabicSample",
                artboard: frame1,
                sentence: "في عام 2026، ستطالع ويكيبيديا على مدار %1$@ يوماً.",
                value: "47",
                numberPath: readDays,
                body: "نص تجريبي للتحقق من عرض النص العربي داخل الرسوم المتحركة.",
                accessibilityLabel: "Arabic sample slide."
            ),
            // The placeholder sits mid-sentence and the script has no spaces to trim.
            slide(
                id: "chineseSample",
                artboard: frame1,
                sentence: "2026年，你在%1$@天里阅读了维基百科。",
                value: "47",
                numberPath: readDays,
                body: "这是一段用于检查中文排版的示例文字。",
                accessibilityLabel: "Chinese sample slide."
            )
        ]
    }

    // TEMPORARY: the sample export, replaced per slide when design delivers the real files.
    private let riveResourceName = "autolayout_multiple_instances_test"
}
