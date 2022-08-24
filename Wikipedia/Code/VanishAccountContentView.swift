import SwiftUI
import WMF

struct VanishAccountContentView: View {
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-account-title", value: "Vanishing process", comment: "Title for the vanishing process screen")
        static let description = WMFLocalizedString("vanish-account-description", value: "Vanishing is a last resort and should only be used when you wish to stop editing forever and also to hide as many of your past associations as possible.\n\nTo initiate the vanishing process please provide the following", comment: "Description for the vanishing process")
        static let usernameFieldTitle = WMFLocalizedString("vanish-account-username-field", value: "Username and user page", comment: "Title for the username and userpage form field")
        static let additionalInformationFieldTitle = WMFLocalizedString("vanish-account-additional-information-field", value: "Additional information", comment: "Title for the additional information form field")
        static let additionalInformationFieldPlaceholder = WMFLocalizedString("vanish-account-additional-information-placeholder", value: "Optional", comment: "Placeholder for the additional information form field")
        static let bottomText = WMFLocalizedString("vanish-account-bottom-text", value: "Account deletion on Wikipedia is done by changing your account name to make it so others cannot recognize your contributions in a process called account vanishing. You may use the form below to request a", comment: "Informative text on accounting deletion on Wikipedia")
        static let courtesyVanishing = WMFLocalizedString("vanish-account-courtesy-vanishing", value: "courtesy vanishing. ", comment: "Text for courtesy vaninshing link")
        static let bottomTextContinuation = WMFLocalizedString("vanish-account-bottom-text-continuation", value: "Vanishing does not guarantee complete anonymity or remove contributions to the projects.", comment: "Continuation on informative text about account deletion on Wikipedia")
        static let buttonText = WMFLocalizedString("vanish-account-button-text", value: "Send request", comment: "Text for button on vanish account request screen")
    }
    
    @SwiftUI.State var userInput = ""
    @SwiftUI.State var toggleModalVisibility = false
    @SwiftUI.State var shouldShowModal = false
    
    var theme: Theme
    var username: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .medium, size: 18)
    private let buttonFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .medium, size: 16)
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 13)
    private let fieldTitleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .subheadline, weight: .regular, size: 15)
    
    private var extraBottomPaddingiOS13: CGFloat {
        // iOS 13doesn't add a bottom scroll view content inset with the keyboard like 14 & 15
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
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font(titleFont))
                                .frame(maxWidth: .infinity, maxHeight: 40)
                                .padding([.leading, .trailing, .top], 20)
                            Text(LocalizedStrings.description)
                                .foregroundColor(Color(theme.colors.secondaryText))
                                .multilineTextAlignment(.leading)
                                .font(Font(bodyFont))
                                .padding([.leading, .trailing, .bottom], 20)
                            
                        }.background(Color(theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
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
                                .padding([.leading, .trailing], 15)
                                .padding([.top], 5)
                            TextView(placeholder: LocalizedStrings.additionalInformationFieldPlaceholder, theme: theme, text: $userInput)
                                .padding([.leading, .trailing], 10)
                                .frame(maxWidth: .infinity, minHeight: 100)
                            Spacer()
                                .frame(height: 12)
                        }.background(Color(theme.colors.paperBackground))
                        VStack {
                            Text("\(LocalizedStrings.bottomText) [\(LocalizedStrings.courtesyVanishing)](https://en.wikipedia.org/wiki/Wikipedia:Courtesy_vanishing) \(LocalizedStrings.bottomTextContinuation)")
                                .foregroundColor(Color(theme.colors.secondaryText))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font(bodyFont))
                                .padding(20)
                            Spacer()
                            Button(action: {
                                openMailClient()
                                print(userInput)
                            }, label: {
                                Text(LocalizedStrings.buttonText)
                                    .font(Font(buttonFont))
                                    .foregroundColor(Color(theme.colors.link))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .frame(width: 335, height: 46)
                                    .background(Color(theme.colors.paperBackground))
                                    .cornerRadius(8)
                                    .padding()
                            })
                            Spacer()
                        }
                    }
                    .padding([.bottom], extraBottomPaddingiOS13)
                    .frame(minHeight: proxy.size.height)
                }
                .background(Color(theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if shouldShowModal {
                    withAnimation(.linear(duration: 0.3)) {
                        toggleModalVisibility.toggle()
                        shouldShowModal.toggle()
                    }
                }
            }
            VanishAccountPopUpAlert(theme:theme, isVisible: $toggleModalVisibility)
        }
    }
    
    func getMailBody() -> String {
        let mainText = WMFLocalizedString("vanish-account-email-text", value: "Hello,\nThis is a request to vanish my Wikipedia account.", comment: "Email content for the vanishing account request")
        let usernameAndPage = WMFLocalizedString("vanish-account-email-username-title", value: "Username and userpage", comment: "")
        let addtionalInformationTitle = WMFLocalizedString("addtional-information-email-title", value: "Additional information", comment: " ")
        let emailBody = "\(mainText)\n\n\(usernameAndPage): \(username)\n\n\(addtionalInformationTitle): \(userInput)"
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
        
        let userDefaults = UserDefaults.standard
        userDefaults.wmf_shouldShowVanishingRequestModal = true
        shouldShowModal = true
        UIApplication.shared.open(mailtoURL)
    }
    
}

struct TextView: UIViewRepresentable {
    
    let placeholder: String
    let theme: Theme
    @Binding var text: String
    
    typealias UIViewType = SwiftUIThemableTextView
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIViewType {
        let textView = UIViewType()
        textView.placeholder = placeholder
        textView.font = UIFont.wmf_font(.callout, compatibleWithTraitCollection: textView.traitCollection)
        textView._delegate = context.coordinator
        textView.apply(theme: theme)
        textView.clipsToBounds = true
        return textView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, placeholder: placeholder)
    }
    
    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<Self>) {
        if !text.isEmpty {
            uiView.text = text
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        
        @Binding var text: String
        let placeholder: String
        
        init(text: Binding<String>, placeholder: String) {
            _text = text
            self.placeholder = placeholder
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.text != placeholder {
                text = textView.text
            }
        }
    }
}
