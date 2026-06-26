import SwiftUI
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFHomeFeedForYouSettingsViewModel: ObservableObject {

    public enum Module: CaseIterable {
        case basedOnYourInterests
        case becauseYouRead
        case continueReading
    }

    let title = WMFLocalizedString("home-feed-for-you-settings-title", value: "Modules", comment: "Navigation bar title for the For You modules settings screen.")
    let headerText = WMFLocalizedString("home-feed-for-you-settings-header", value: "Turning off a module hides it from your \"For you\" feed. You can re-enable it here at any time.", comment: "Header text describing what turning For You feed modules on or off does.")

    private let homeDataController: WMFHomeDataController

    @Published public var basedOnYourInterestsIsOn: Bool
    @Published public var becauseYouReadIsOn: Bool
    @Published public var continueReadingIsOn: Bool

    public var onToggleModule: ((Module, Bool) -> Void)?
    public var didTapWhatsDriving: (() -> Void)?

    public private(set) var sections: [SettingsSection] = []

    public init(didTapWhatsDriving: (() -> Void)? = nil, homeDataController: WMFHomeDataController = .shared) {
        self.homeDataController = homeDataController
        self.basedOnYourInterestsIsOn = homeDataController.forYouBasedOnInterestsIsOn()
        self.becauseYouReadIsOn = homeDataController.forYouBecauseYouReadIsOn()
        self.continueReadingIsOn = homeDataController.forYouContinueReadingIsOn()
        self.didTapWhatsDriving = didTapWhatsDriving
        self.onToggleModule = { [weak self] module, isOn in
            guard let self else { return }
            switch module {
            case .basedOnYourInterests: self.homeDataController.setForYouBasedOnInterestsIsOn(isOn)
            case .becauseYouRead: self.homeDataController.setForYouBecauseYouReadIsOn(isOn)
            case .continueReading: self.homeDataController.setForYouContinueReadingIsOn(isOn)
            }
        }
        self.sections = buildSections()
    }

    private func buildSections() -> [SettingsSection] {
        let basedOnYourInterests = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-for-you-based-on-interests-title", value: "Based on your interests", comment: "Title for the Based on your interests module toggle."),
            subtitle: WMFLocalizedString("home-feed-for-you-based-on-interests-subtitle", value: "Articles tailored to the topics you chose.", comment: "Subtitle describing the Based on your interests module."),
            accessory: .toggle(binding(for: .basedOnYourInterests)),
            action: nil
        )

        let whatsDriving = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-for-you-whats-driving-title", value: "What's driving your feed", comment: "Title for the link row that explains what is driving the user's For You feed."),
            subtitle: nil,
            titleStyle: .link,
            accessory: .none,
            action: didTapWhatsDriving
        )

        let becauseYouRead = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-for-you-because-you-read-title", value: "Because you read", comment: "Title for the Because you read module toggle."),
            subtitle: WMFLocalizedString("home-feed-for-you-because-you-read-subtitle", value: "Suggestions based on a recent article from your history", comment: "Subtitle describing the Because you read module."),
            accessory: .toggle(binding(for: .becauseYouRead)),
            action: nil
        )

        let continueReading = SettingsItem(
            image: nil,
            color: nil,
            title: WMFLocalizedString("home-feed-for-you-continue-reading-title", value: "Continue reading", comment: "Title for the Continue reading module toggle."),
            subtitle: WMFLocalizedString("home-feed-for-you-continue-reading-subtitle", value: "Jump back into articles you didn't finish", comment: "Subtitle describing the Continue reading module."),
            accessory: .toggle(binding(for: .continueReading)),
            action: nil
        )

        return [
            SettingsSection(header: headerText, footer: nil, items: [basedOnYourInterests, whatsDriving, becauseYouRead, continueReading])
        ]
    }

    private func binding(for module: Module) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                guard let self else { return false }
                switch module {
                case .basedOnYourInterests: return self.basedOnYourInterestsIsOn
                case .becauseYouRead: return self.becauseYouReadIsOn
                case .continueReading: return self.continueReadingIsOn
                }
            },
            set: { [weak self] newValue in
                guard let self else { return }
                switch module {
                case .basedOnYourInterests: self.basedOnYourInterestsIsOn = newValue
                case .becauseYouRead: self.becauseYouReadIsOn = newValue
                case .continueReading: self.continueReadingIsOn = newValue
                }
                self.onToggleModule?(module, newValue)
            }
        )
    }
}
