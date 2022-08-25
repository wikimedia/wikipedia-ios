import SwiftUI
import WMF

struct VanishAccountContentView: View {
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-account-title", value: "Vanishing process", comment: "Title for the vanishing process screen")
        static let description = WMFLocalizedString("vanish-account-description", value: "Vanishing is a last resort and should only be used when you wish to stop editing forever and also to hide as many of your past associations as possible.\n\nTo initiate the vanishing process please provide the following", comment: "Description for the vanishing process")
        static let usernameFieldTitle = WMFLocalizedString("vanish-account-username-field", value: "Username and user page", comment: "Title for the username and userpage form field")
        static let additionalInformationFieldTitle = WMFLocalizedString("vanish-account-additional-information-field", value: "Additional information", comment: "Title for the additional information form field")
        static let additionalInformationFieldPlaceholder = WMFLocalizedString("vanish-account-additional-information-placeholder", value: "Optional", comment: "Placeholder for the additional information form field")
        static let buttonText = WMFLocalizedString("vanish-account-button-text", value: "Send request", comment: "Text for button on vanish account request screen")
    }
    
    @SwiftUI.ObservedObject var userInput: UserInput
    @SwiftUI.State var isModalVisible = false
    @SwiftUI.State var shouldShowModalOnForeground = false
    
    var theme: Theme
    var username: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .medium, size: 18)
    private let buttonFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .medium, size: 16)
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 13)
    private let fieldTitleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .subheadline, weight: .regular, size: 15)
    
    private var extraBottomPaddingiOS13: CGFloat {
        // iOS 13 doesn't add a bottom scroll view content inset with the keyboard like 14 & 15
        // Adding some extra padding here so it's easier to scroll and see the text view on smaller iOS13 devices
        if #available(iOS 14, *) {
            return 0
        } else {
            return 100
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        VStack {
                            Text(LocalizedStrings.title)
                                .foregroundColor(Color(theme.colors.primaryText))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font(titleFont))
                                .frame(maxWidth: .infinity, maxHeight: 40)
                            Text(LocalizedStrings.description)
                                .foregroundColor(Color(theme.colors.secondaryText))
                                .font(Font(bodyFont))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color(theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        VStack {
                            Text(LocalizedStrings.usernameFieldTitle)
                                .foregroundColor(Color(theme.colors.secondaryText))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font(fieldTitleFont))
                                .padding([.top], 10)
                                .padding([.leading, .trailing], 20)
                            Text(username)
                                .foregroundColor(Color(theme.colors.secondaryText))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font(fieldTitleFont))
                                .padding([.bottom], 5)
                                .padding([.top], 2)
                                .padding([.leading, .trailing], 20)
                            Divider().padding([.leading], 20)
                            Text(LocalizedStrings.additionalInformationFieldTitle)
                                .foregroundColor(Color(theme.colors.link))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font(fieldTitleFont))
                                .padding([.leading, .trailing], 20)
                                .padding([.top], 5)
                            TextView(placeholder: LocalizedStrings.additionalInformationFieldPlaceholder, theme: theme, text: $userInput.text)
                                .padding([.leading, .trailing], 20)
                                .frame(maxWidth: .infinity, minHeight: 100)
                            Spacer()
                                .frame(height: 12)
                        }
                        .background(Color(theme.colors.paperBackground))
                        .frame(maxWidth: .infinity, minHeight: 300)
                        VStack {
                            VanishAccountFooterView()
                                .foregroundColor(Color(theme.colors.secondaryText))
                                .fixedSize(horizontal: false, vertical: true)
                                .font(Font(bodyFont))
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Button(action: {
                                openMailClient()
                            }, label: {
                                Text(LocalizedStrings.buttonText)
                                    .font(Font(buttonFont))
                                    .foregroundColor(Color(theme.colors.link))
                                    .padding()
                                    .frame(minWidth: 335)
                                    .frame(height: 46)
                                    .background(Color(theme.colors.paperBackground))
                                    .cornerRadius(8)
                                    .padding()
                            })
                            Spacer()
                        }
                    }
                    .padding([.bottom], extraBottomPaddingiOS13)
                    .frame(minHeight: proxy.size.height)
                    .frame(maxWidth: .infinity)
                }
                .background(Color(theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if shouldShowModalOnForeground {
                    withAnimation(.linear(duration: 0.3)) {
                        isModalVisible = true
                        shouldShowModalOnForeground = false
                    }
                }
            }
            VanishAccountPopUpAlertView(theme:theme, isVisible: $isModalVisible, userInput: $userInput.text)
        }
        
    }
    
    func getMailBody() -> String {
        let mainText = WMFLocalizedString("vanish-account-email-text", value: "Hello,\nThis is a request to vanish my Wikipedia account.", comment: "Email content for the vanishing account request")
        let usernameAndPage = WMFLocalizedString("vanish-account-email-username-title", value: "Username and userpage", comment: "Text for the username and userpage items for the request vanishing email body")
        let additionalInformationTitle = WMFLocalizedString("additional-information-email-title", value: "Additional information", comment: "Text for the additional information for the request vanishing email body")
        let emailBody = "\(mainText)\n\n\(usernameAndPage): \(username)\n\n\(additionalInformationTitle): \(userInput.text)"
        return emailBody
    }
    
    func openMailClient() {
        let address = "renamers@wikimedia.org"
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
