public struct WMFYearInReviewContributorSlideViewModel {
    public enum ContributionStatus {
        case contributor
        case noncontributor
    }
    
    public let gifName: String
    public let altText: String
    public let title: String
    public let subtitle: String
    public let loggingID: String
    public let onAppear: () -> Void
    public let contributionStatus: ContributionStatus
    public let onTappedDonateButton: () -> Void
    public let onToggleIcon: (Bool) -> Void
    public let donateButtonTitle: String
    public let toggleButtonTitle: String
    public let toggleButtonSubtitle: String
    
    public init(gifName: String, altText: String, title: String, subtitle: String, loggingID: String, onAppear: @escaping () -> Void, contributionStatus: ContributionStatus, onTappedDonateButton: @escaping () -> Void, onToggleIcon: @escaping (Bool) -> Void, donateButtonTitle: String, toggleButtonTitle: String, toggleButtonSubtitle: String) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.subtitle = subtitle
        self.loggingID = loggingID
        self.onAppear = onAppear
        self.contributionStatus = contributionStatus
        self.onTappedDonateButton = onTappedDonateButton
        self.onToggleIcon = onToggleIcon
        self.donateButtonTitle = donateButtonTitle
        self.toggleButtonTitle = toggleButtonTitle
        self.toggleButtonSubtitle = toggleButtonSubtitle
    }
    
    public enum SubtitleType {
        case html
        case standard
    }
    
    public var subtitletype: SubtitleType {
        switch contributionStatus {
        case .contributor:
            return .standard
        case .noncontributor:
            return .html
        }
    }
}

