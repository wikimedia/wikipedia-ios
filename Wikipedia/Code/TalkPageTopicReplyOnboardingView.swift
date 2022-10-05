import SwiftUI
import WMF

struct TalkPageTopicReplyOnboardingView: View {

    // MARK: - Nested Types

    enum LocalizedStrings {
        static let title = WMFLocalizedString("talk-pages-topic-reply-onboarding-title", value: "Talk pages", comment: "Title of user education onboarding view for user and article talk pages.")
        static let body = WMFLocalizedString("talk-pages-topic-reply-onboarding-body", value: "Talk pages are where people discuss how to make content on Wikipedia the best that it can be. Add a new discussion topic to connect and collaborate with a community of Wikipedians.\n\nPlease be kind, we are all humans here.", comment: "Body text for user education onboarding view for user and article talk pages. Please do not translate the \n\n characters as these indicate where to insert new lines.")
    }

    // MARK: - Properties

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var theme: Theme
    var dismissAction: (() -> Void)?

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 16
    }

    var buttonTextColor: Color {
        switch theme {
        case .dark, .black:
            return Color(theme.colors.primaryText)
        default:
            return Color(theme.colors.paperBackground)
        }
    }

    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .bold, size: 28)
    private let buttonFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .semibold, size: 17)

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
                    Image("share-building")
                    Spacer(minLength: 31)
                    Text(LocalizedStrings.body)
                        .font(.callout)
                }
                .padding(sizeClassPadding)
            }
            ZStack(alignment: .bottom, content: {
                VStack {
                    Button(action: {
                        dismissAction?()
                    }, label: {
                        Text(CommonStrings.okTitle)
                            .font(Font(buttonFont))
                            .foregroundColor(buttonTextColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(width: 335, height: 46)
                            .background(Color(theme.colors.link))
                            .cornerRadius(8)
                            .padding()
                    })
                    Spacer().frame(height: 18)
                }
            })
            .padding(sizeClassPadding)
        }
    }
    
}
