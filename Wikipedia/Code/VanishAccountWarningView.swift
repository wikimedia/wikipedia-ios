import WMFComponents
import SwiftUI
import WMF

struct VanishAccountWarningView: View {

    // MARK: - Nested Types

    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-account-warning-title", value: "Warning", comment: "Title of vanish account warning view.")
        static let body = WMFLocalizedString("vanish-account-warning-body", value: "Vanishing is a **last resort** and should **only be used when you wish to stop editing forever** and also to hide as many of your past associations as possible.\n\nAccount deletion on Wikipedia is done by changing your account name to make it so others cannot recognize your contributions in a process called account vanishing. **Vanishing does not guarantee complete anonymity or remove contributions to the projects**.", comment: "Body text of vanish account warning view. Please do not translate or remove the `**` characters as these indicate which region of the text to display in bold.")
        static let continueButton = WMFLocalizedString("vanish-account-continue-button-title", value: "Continue", comment: "Title of button presented in the vanish account warning view.")

        static var attributedBody: AttributedString? {
            return try? AttributedString(markdown: LocalizedStrings.body, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        }
    }

    // MARK: - Properties

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var theme: Theme
    var dismissAction: (() -> Void)?
    var continueAction: (() -> Void)?

    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }

    private var containerPadding: CGFloat {
        verticalSizeClass == .regular ? sizeClassPadding : 0
    }

    private var verticalSpacing: CGFloat {
        return verticalSizeClass == .regular ? 64 : 16
    }

    private var continueButtonTextColor: Color {
        switch theme {
        case .dark, .black:
            return Color(theme.colors.primaryText)
        default:
            return Color(theme.colors.paperBackground)
        }
    }

    // The Markdown-less version of the String to display on iOS <15 or `AttributedString` failure
    private var fallbackBodyString: String {
        return LocalizedStrings.body.replacingOccurrences(of: "**", with: "")
    }

    private let titleFont = WMFFont.for(.boldTitle1)
    private let primaryButtonFont = WMFFont.for(.boldHeadline)
    private let secondaryButtonFont = WMFFont.for(.semiboldHeadline)

    // MARK: - Content

    var body: some View {
        Group {
            ScrollView {
                VStack {
                    Spacer(minLength: verticalSpacing)
                    Text(LocalizedStrings.title)
                        .font(Font(titleFont))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(theme.colors.primaryText))
                    Spacer(minLength: 50)
                        Text(LocalizedStrings.attributedBody ?? AttributedString(fallbackBodyString))
                            .foregroundColor(Color(theme.colors.primaryText))
                }
                .padding(sizeClassPadding)
            }
            ZStack(alignment: .bottom, content: {
                VStack {
                    Button(action: {
                        continueAction?()
                    }, label: {
                        Text(LocalizedStrings.continueButton)
                            .font(Font(primaryButtonFont))
                            .foregroundColor(continueButtonTextColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(width: 335, height: 46)
                            .background(Color(theme.colors.error))
                            .cornerRadius(8)
                            .padding()
                    })
                    Spacer().frame(height: 4)
                    Button(CommonStrings.cancelActionTitle) {
                        dismissAction?()
                    }
                        .font(Font(secondaryButtonFont))
                        .foregroundColor(Color(theme.colors.link))
                    Spacer().frame(height: 18)
                }
            })
            .padding(containerPadding)
        }
    }

}
