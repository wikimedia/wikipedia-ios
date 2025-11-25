import Foundation
import SwiftUI
import WMFData

public class WMFYearInReviewContributorSlideViewModel: ObservableObject, WMFYearInReviewSlideViewModelProtocol {
    public enum ContributionStatus {
        case contributor
        case noncontributor
    }
    
    public let gifName: String
    public let altText: String
    public let title: String
    public let subtitle: String
    public let loggingID: String
    public let contributionStatus: ContributionStatus
    
    public let onTappedDonateButton: () -> Void
    public let onToggleIcon: ((Bool) -> Void)?
    public let onInfoButtonTap: () -> Void
    public let donateButtonTitle: String
    public let toggleButtonTitle: String
    public let toggleButtonSubtitle: String
    @Published var isIconOn: Bool
    
    public init(gifName: String, altText: String, title: String, subtitle: String, loggingID: String, contributionStatus: ContributionStatus, onTappedDonateButton: @escaping () -> Void, onToggleIcon: ((Bool) -> Void)? = nil, onInfoButtonTap: @escaping () -> Void, donateButtonTitle: String, toggleButtonTitle: String, toggleButtonSubtitle: String, isIconOn: Bool = false) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.subtitle = subtitle
        self.loggingID = loggingID
        self.contributionStatus = contributionStatus
        self.onTappedDonateButton = onTappedDonateButton
        self.onToggleIcon = onToggleIcon
        self.onInfoButtonTap = onInfoButtonTap
        self.donateButtonTitle = donateButtonTitle
        self.toggleButtonTitle = toggleButtonTitle
        self.toggleButtonSubtitle = toggleButtonSubtitle
        self.isIconOn = isIconOn
    }
    
    public enum SubtitleType {
        case html
        case standard
        case markdown
    }
    
    public var subtitletype: SubtitleType {
        switch contributionStatus {
        case .contributor:
            return .standard
        case .noncontributor:
            return .markdown
        }
    }
}

