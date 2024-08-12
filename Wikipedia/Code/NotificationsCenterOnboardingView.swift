import WMFComponents
import SwiftUI
import WMF

struct NotificationsCenterOnboardingView: View {

    // MARK: - Nested Types

    enum LocalizedStrings {
        static let title = WMFLocalizedString("notifications-center-onboarding-modal-title", value: "Editing notifications", comment: "Title of onboarding modal displayed when first launching the Notifications Center.")
        static let notificationsAlertsTitle = WMFLocalizedString("notifications-center-onboarding-modal-notifications-alerts-title", value: "Notifications and alerts", comment: "Title of onboarding education row displayed when first launching the Notifications Center.")
        static let notificationsAlertsMessage = WMFLocalizedString("notifications-center-onboarding-modal-notifications-alerts-message", value: "Notifications help keep you informed of activity related to your edits and account.", comment: "Detail message for onboarding education row displayed when first launching the Notifications Center.")
        static let filterTitle = WMFLocalizedString("notifications-center-onboarding-modal-filters-title", value: "Filters", comment: "Title of onboarding education row displayed when first launching the Notifications Center.")
        static let filterMessage = WMFLocalizedString("notifications-center-onboarding-modal-filters-message", value: "Filter your notifications by read status and type to easily narrow down your inbox.", comment: "Detail message for onboarding education row when first launching the Notifications Center.")
        static let inboxTitle = WMFLocalizedString("notifications-center-onboarding-modal-project-inboxes-title", value: "Project inboxes", comment: "Title of onboarding education row displayed when first launching the Notifications Center.")
        static let inboxMessage = WMFLocalizedString("notifications-center-onboarding-modal-project-inboxes-message", value: "View all your unread messages from different language Wikipedias and Wikimedia projects in one place.", comment: "Detail message for onboarding education row displayed when first launching the Notifications Center.")
        static let pushTitle = WMFLocalizedString("notifications-center-onboarding-modal-push-notifications-title", value:  "Push notifications", comment: "Title of onboarding education row displayed when first launching the Notifications Center.")
        static let pushMessage = WMFLocalizedString("notifications-center-onboarding-modal-push-notifications-message", value: "Opt in to push notifications to keep up to date with your editing messages and alerts while on the go.", comment: "Detail message for onboarding education row displayed when first launching the Notifications Center.")
        static let continueButton = WMFLocalizedString("notifications-center-onboarding-modal-continue-action", value: "Continue", comment: "Button title of primary action displayed when first launching the Notifications Center.")
        static let learnMoreButton = WMFLocalizedString("notifications-center-onboarding-modal-learn-more-action", value: "Learn more about notifications", comment: "Button title of secondary action displayed when first launching the Notifications Center.")
    }

    // MARK: - Properties

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var theme: Theme
    var dismissAction: (() -> Void)?

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 16
    }

    var continueButtonTextColor: Color {
        switch theme {
        case .dark, .black:
            return Color(theme.colors.primaryText)
        default:
            return Color(theme.colors.paperBackground)
        }
    }

    private let titleFont = WMFFont.for(.boldTitle3)
    private let primaryButtonFont = WMFFont.for(.boldCallout)
    private let secondaryButtonFont = WMFFont.for(.boldCallout)

    // MARK: - Content

    var body: some View {
        Group {
            ScrollView {
                VStack {
                    Spacer(minLength: 64)
                    Text(LocalizedStrings.title)
                        .font(Font(titleFont))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(theme.colors.primaryText))
                    Spacer(minLength: 50)
                    NotificationsCenterOnboardingRowView(theme: theme, image: .notificationsAndAlerts, header: LocalizedStrings.notificationsAlertsTitle, message: LocalizedStrings.notificationsAlertsMessage)
                    Spacer().frame(height: 0)
                    NotificationsCenterOnboardingRowView(theme: theme, image: .filter, header: LocalizedStrings.filterTitle, message: LocalizedStrings.filterMessage)
                    Spacer().frame(height: 0)
                    NotificationsCenterOnboardingRowView(theme: theme, image: .inbox, header: LocalizedStrings.inboxTitle, message: LocalizedStrings.inboxMessage)
                    Spacer().frame(height: 0)
                    NotificationsCenterOnboardingRowView(theme: theme, image: .push, header: LocalizedStrings.pushTitle, message: LocalizedStrings.pushMessage)
                }
                .padding(sizeClassPadding)
            }
            ZStack(alignment: .bottom, content: {
                VStack {
                    Button(action: {
                        dismissAction?()
                    }, label: {
                        Text(LocalizedStrings.continueButton)
                            .font(Font(primaryButtonFont))
                            .foregroundColor(continueButtonTextColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(width: 335, height: 46)
                            .background(Color(theme.colors.link))
                            .cornerRadius(8)
                            .padding()
                    })
                    Spacer().frame(height: 4)
                    Button(LocalizedStrings.learnMoreButton) {
                        userDidTapLearnMore()
                    }
                        .font(Font(secondaryButtonFont))
                        .foregroundColor(Color(theme.colors.link))
                    Spacer().frame(height: 18)
                }
            })
            .padding(sizeClassPadding)
        }
    }

    // MARK: - Actions

    func userDidTapLearnMore() {
        guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ#Notifications") else {
            return
        }

        UIApplication.shared.open(url)
    }

}

fileprivate struct NotificationsCenterOnboardingRowView: View {

    // MARK: - Properties

    var theme: Theme
    var image: OnboardingRowIconImage
    var header: String
    var message: String

    private let headerFont = WMFFont.for(.semiboldHeadline)
    private let bodyFont = WMFFont.for(.footnote)

    // MARK: - Content

    var body: some View {
        HStack(alignment: .top) {
            image.imageForTheme(theme: theme)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 28, maxHeight: .infinity, alignment: .top)
                .offset(y: 10)
                .accessibility(label: image.accessibilityLabel)
            Spacer().frame(width: 16)
            VStack(alignment: .leading) {
                Text(header)
                    .font(Font(headerFont))
                    .foregroundColor(Color(theme.colors.primaryText))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Spacer().frame(height: 5)
                Text(message)
                    .font(Font(bodyFont))
                    .foregroundColor(Color(theme.colors.secondaryText))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding()
    }

}

fileprivate enum OnboardingRowIconImage {

    case notificationsAndAlerts
    case filter
    case inbox
    case push

    func imageForTheme(theme: Theme) -> SwiftUI.Image {
        let darkTheme = theme == .dark || theme == .black
        switch self {
        case .notificationsAndAlerts:
            return Image("notifications-center-onboarding-bell" + (darkTheme ? "-alt" : ""))
        case .filter:
            return Image("notifications-center-onboarding-filter" + (darkTheme ? "-alt" : ""))
        case .inbox:
            return Image("notifications-center-onboarding-inbox" + (darkTheme ? "-alt" : ""))
        case .push:
            return Image("notifications-center-onboarding-push" + (darkTheme ? "-alt" : ""))
        }
    }

    var accessibilityLabel: Text {
        switch self {
        case .notificationsAndAlerts:
            return Text(NotificationsCenterOnboardingView.LocalizedStrings.notificationsAlertsTitle)
        case .filter:
            return Text(NotificationsCenterOnboardingView.LocalizedStrings.filterTitle)
        case .inbox:
            return Text(NotificationsCenterOnboardingView.LocalizedStrings.inboxTitle)
        case .push:
            return Text(NotificationsCenterOnboardingView.LocalizedStrings.pushTitle)
        }
    }

}
