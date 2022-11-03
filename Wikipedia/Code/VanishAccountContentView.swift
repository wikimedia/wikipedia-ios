import SwiftUI
import WMF

struct VanishAccountContentView: View {
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-account-title", value: "Vanishing process", comment: "Title for the vanishing process screen")
        static let description = WMFLocalizedString("vanish-account-description", value: "To initiate the vanishing process please provide the following:", comment: "Description for the vanishing process")
        static let usernameFieldTitle = CommonStrings.usernameFieldTitle
        static let additionalInformationFieldTitle = WMFLocalizedString("vanish-account-additional-information-field", value: "Additional information", comment: "Title for the additional information form field")
        static let additionalInformationFieldPlaceholder = WMFLocalizedString("vanish-account-additional-information-placeholder", value: "Optional", comment: "Placeholder for the additional information form field")
        static let buttonText = WMFLocalizedString("vanish-account-button-text", value: "Send request", comment: "Text for button on vanish account request screen")
        static let learnMoreButtonText = CommonStrings.learnMoreButtonText
    }

    @SwiftUI.ObservedObject var userInput: UserInput
    @SwiftUI.State var isModalVisible = false
    @SwiftUI.State var shouldShowModalOnForeground = false
    @SwiftUI.State var shouldShowButtonStack = true

    var theme: Theme
    var username: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .medium, size: 18)
    private let buttonFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .medium, size: 16)
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 13)
    private let fieldTitleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .subheadline, weight: .regular, size: 16)

    private var extraBottomPadding: CGFloat {
        // Extra padding to accommodate the one or two (depending on OS version) floating bottom buttons
        if #available(iOS 15, *) {
            return 100
        } else {
            return 200
        }
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text(LocalizedStrings.title)
                            .foregroundColor(Color(theme.colors.primaryText))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font(titleFont))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                            .frame(height: 16)
                        Text(LocalizedStrings.description)
                            .foregroundColor(Color(theme.colors.secondaryText))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font(bodyFont))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    VStack {
                        Text(LocalizedStrings.usernameFieldTitle)
                            .foregroundColor(Color(theme.colors.secondaryText))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(Font(fieldTitleFont))
                            .padding([.top], 16)
                            .padding([.leading, .trailing], 16)
                        Text(username)
                            .foregroundColor(Color(theme.colors.secondaryText))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(Font(fieldTitleFont))
                            .padding([.bottom], 5)
                            .padding([.top], 2)
                            .padding([.leading, .trailing], 16)
                        Divider().padding([.leading], 16)
                        Text(LocalizedStrings.additionalInformationFieldTitle)
                            .foregroundColor(Color(theme.colors.link))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(Font(fieldTitleFont))
                            .padding([.leading, .trailing], 16)
                            .padding([.top], 8)
                        TextView(placeholder: LocalizedStrings.additionalInformationFieldPlaceholder, theme: theme, text: $userInput.text)
                            .padding([.leading, .trailing], 16)
                            .frame(maxWidth: .infinity, minHeight: 50)
                        Spacer()
                            .frame(height: 12)
                    }
                    .background(Color(theme.colors.paperBackground))
                    VStack(spacing: 0) {
                        VanishAccountFooterView()
                            .foregroundColor(Color(theme.colors.secondaryText))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font(bodyFont))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                }
                .padding([.bottom], extraBottomPadding)
            }
            .background(Color(theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if shouldShowModalOnForeground {
                    withAnimation(.linear(duration: 0.3)) {
                        isModalVisible = true
                        shouldShowModalOnForeground = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)) { _ in
                shouldShowButtonStack = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)) { _ in
                shouldShowButtonStack = true
            }
            if shouldShowButtonStack {
                VStack {
                    Spacer()
                    Button(action: {
                        openMailClient()
                    }, label: {
                        Text(LocalizedStrings.buttonText)
                            .font(Font(buttonFont))
                            .foregroundColor(Color(theme.colors.link))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color(theme.colors.paperBackground))
                            .cornerRadius(8)
                    })
                    .padding(16)
                    if #unavailable(iOS 15) {
                        Button(action: {
                            goToVanishPage()
                        }, label: {
                            Text(LocalizedStrings.learnMoreButtonText)
                                .font(Font(buttonFont))
                                .foregroundColor(Color(theme.colors.link))
                                .frame(minWidth: 335)
                                .frame(height: 46)
                                .background(Color(theme.colors.baseBackground))
                        })
                    }
                }
                .padding(0)
            }
            Spacer()
            VanishAccountPopUpAlertView(theme:theme, isVisible: $isModalVisible, userInput: $userInput.text)
        }
        
    }
    
    func getMailBody() -> String {
        let mainText = WMFLocalizedString("vanish-account-email-text", value: "Hello,\nThis is a request to vanish my Wikipedia account.", comment: "Email content for the vanishing account request")
        let usernameAndPage = CommonStrings.usernameFieldTitle
        let additionalInformationTitle = WMFLocalizedString("additional-information-email-title", value: "Additional information", comment: "Text for the additional information for the request vanishing email body")
        let emailBody = "\(mainText)\n\n\(usernameAndPage): \(username)\n\n\(additionalInformationTitle): \(userInput.text)"
        return emailBody
    }
    
    func openMailClient() {
        let address = "privacy@wikimedia.org"
        let subject = WMFLocalizedString("vanishing-request-email-title", value: "Request for courtesy vanishing", comment: "Title for vanishing request email")
        let body = getMailBody()
        let mailto = "mailto:\(address)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        guard let encodedMailto = mailto, let mailtoURL = URL(string: encodedMailto), UIApplication.shared.canOpenURL(mailtoURL) else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(CommonStrings.noEmailClient, sticky: false, dismissPreviousAlerts: false)
            return
        }

        shouldShowModalOnForeground = true
        UIApplication.shared.open(mailtoURL)
    }
    
    func goToVanishPage() {
        if let url = URL(string: "https://meta.wikimedia.org/wiki/Right_to_vanish") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
}

struct TextView: UIViewRepresentable {
    
    let placeholder: String
    let theme: Theme
    @Binding var text: String
    
    typealias UIViewType = SwiftUITextView
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIViewType {
        let textView = UIViewType()
        textView.setup(placeholder: placeholder, theme: theme)
        textView.delegate = context.coordinator
        let font = UIFont.wmf_font(.callout, compatibleWithTraitCollection: textView.traitCollection)
        textView.font = font
        textView.placeholderLabel.font = font
        return textView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, placeholder: placeholder)
    }
    
    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<Self>) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        
        @Binding var text: String
        let placeholder: String
        
        init(text: Binding<String>, placeholder: String) {
            _text = text
            self.placeholder = placeholder
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}
