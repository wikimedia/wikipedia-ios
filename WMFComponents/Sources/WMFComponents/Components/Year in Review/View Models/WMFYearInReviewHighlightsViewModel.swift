import UIKit
import SwiftUI
import WMFData

public class WMFYearInReviewSlideHighlightsViewModel {

    public struct LocalizedStrings {
        let title: String
        let subtitle: String
        let buttonTitle: String
        let logoCaption: String

        public init(title: String, subtitle: String, buttonTitle: String, logoCaption: String) {
            self.title = title
            self.subtitle = subtitle
            self.buttonTitle = buttonTitle
            self.logoCaption = logoCaption
        }
    }

    let infoBoxViewModel: WMFInfoboxViewModel
    let loggingID: String
    public let localizedStrings: LocalizedStrings
    private weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?
    let hashtag: String
    let plaintextURL: String
    let tappedShare: @MainActor () -> Void

    public init(infoBoxViewModel: WMFInfoboxViewModel, loggingID: String, localizedStrings: LocalizedStrings, coordinatorDelegate: YearInReviewCoordinatorDelegate? = nil, hashtag: String, plaintextURL: String, tappedShare: @escaping @MainActor () -> Void) {
        self.infoBoxViewModel = infoBoxViewModel
        self.loggingID = loggingID
        self.localizedStrings = localizedStrings
        self.coordinatorDelegate = coordinatorDelegate
        self.hashtag = hashtag
        self.plaintextURL = plaintextURL
        self.tappedShare = tappedShare
    }
}
