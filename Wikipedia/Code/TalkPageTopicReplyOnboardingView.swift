import WMFComponents
import SwiftUI
import WMF

struct TalkPageTopicReplyOnboardingView: View {

    // MARK: - Nested Types

    enum LocalizedStrings {
        static let title = WMFLocalizedString("talk-pages-topic-reply-onboarding-title", value: "Talk pages", comment: "Title of user education onboarding view for user and article talk pages.")
        static let body = WMFLocalizedString("talk-pages-topic-reply-onboarding-body", value: "Talk pages are where people discuss how to make content on Wikipedia the best that it can be. Add a new discussion topic to connect and collaborate with a community of Wikipedians.\n\nPlease be kind, we are all humans here.", comment: "Body text for user education onboarding view for user and article talk pages.")

        static var bodyAttributedString: AttributedString? = {
            let localizedString = WMFLocalizedString("talk-pages-topic-reply-onboarding-body-ios15", value: "Talk pages are where %1$@people discuss how to make content on Wikipedia the best that it can be.%1$@ Add a new discussion topic to connect and collaborate with a community of Wikipedians.", comment: "Body text for user education onboarding view for user and article talk pages. Parameters:\n* %1$@ - app-specific non-text formatting")
            let attributedString = String.localizedStringWithFormat(
                localizedString,
                "**"
            )
            return try? AttributedString(markdown: attributedString)
        }()

        static var bodySecondPartiOS15 = WMFLocalizedString("talk-pages-topic-reply-onboarding-body-note-ios15", value: "Please be kind, we are all humans here.", comment: "Body text for user education onboarding view for user and article talk pages on iOS 15+")
    }

    // MARK: - Properties

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var theme: Theme
    var dismissAction: (() -> Void)?

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 16
    }

    var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }

    var buttonTextColor: Color {
        switch theme {
        case .dark, .black:
            return Color(theme.colors.primaryText)
        default:
            return Color(theme.colors.paperBackground)
        }
    }

    private let titleFont = WMFFont.for(.title1)
    private let callout = WMFFont.for(.callout)

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
                    Spacer(minLength: 44)
                    Image("talk-pages-empty-view-image")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150, alignment: .center)
                        .accessibilityHidden(true)
                    Spacer(minLength: 31)
                    if let text = LocalizedStrings.bodyAttributedString {
                        Text(text)
                            .font(Font(callout))
                            .foregroundColor(Color(theme.colors.primaryText))
                        Spacer(minLength: 24)
                        Text(LocalizedStrings.bodySecondPartiOS15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(Font(callout))
                            .foregroundColor(Color(theme.colors.primaryText))
                    } else {
                        Text(LocalizedStrings.body)
                            .font(Font(callout))
                            .foregroundColor(Color(theme.colors.primaryText))
                    }
                }
                .padding([.top, .bottom],sizeClassPadding)
                .padding([.leading, .trailing], horizontalPadding)
            }
            ZStack(alignment: .bottom, content: {
                VStack {
                    Button(action: {
                        dismissAction?()
                    }, label: {
                        Text(CommonStrings.okTitle)
                            .font(Font(callout))
                            .foregroundColor(buttonTextColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(width: 335, height: 46)
                            .background(Color(theme.colors.link))
                            .cornerRadius(8)
                            .padding()
                    })
                    .accessibilityHint(WMFLocalizedString("talk-page-onboarding-button-accessibility-label", value: "Double tap to return to reply", comment: "Accessibility text for the ok button on the talk pages onboarding modal"))
                    Spacer().frame(height: 18)
                }
            })
            .padding(sizeClassPadding)
        }
    }
    
}
