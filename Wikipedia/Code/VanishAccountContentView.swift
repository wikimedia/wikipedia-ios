import SwiftUI
import WMF

struct VanishAccountContentView: View {
    @SwiftUI.State var userInput: String = ""
    @SwiftUI.State var showPopUp: Bool = false
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-account-title", value: "Vanishing process", comment: "Title for the vanishing process screen")
        static let description = WMFLocalizedString("vanish-account-description", value: "Vanishing is a last resort and should only be used when you wish to stop editing forever and also to hide as many of your past associations as possible.\n\nTo initiate the vanishing process please provide the following:", comment: "Description for the vanishing process")
        static let usernameFieldTitle = WMFLocalizedString("vanish-account-username-field", value: "Username and user page", comment: "Title for the username and userpage form field")
        static let additionalInformationFieldTitle = WMFLocalizedString("vanish-account-additional-information-field", value: "Additional information", comment: "Titl for the additional information form field")
        static let bottomText = WMFLocalizedString("vanish-account-bottom-text", value: "Account deletion on Wikipedia is done by changing your account name to make it so others cannot recognize your contributions in a process called account vanishing. You may use the form below to request a", comment: "Informative text on accounting deletion on Wikipedia")
        static let courtesyVanishing = WMFLocalizedString("vanish-account-courtesy-vanishing", value: "courtesy vanishing. ", comment: "Text for courtesy vaninshing link")
        static let bottomTextContinuation = WMFLocalizedString("vanish-account-bottom-text-continuation", value: "Vanishing does not guarantee complete anonymity or remove contributions to the projects.", comment: "Continuation on informative text about account deletion on Wikipedia")
        static let buttonText = WMFLocalizedString("vanish-account-button-text", value: "Send request", comment: "Text for button on vanish account request screen")
    }
    
    var theme: Theme
    var username: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .medium, size: 16)
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 13)
    private let fieldTitleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .subheadline, weight: .regular, size: 15)
    
    var body: some View {
        ScrollView {
             ZStack {
                VStack {
                    VStack {
                        Text(LocalizedStrings.title)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(Font(titleFont))
                            .frame(maxWidth: .infinity, maxHeight: 40)
                            .padding([.leading, .trailing, .top], 20)
                        Text(LocalizedStrings.description)
                            .fontWeight(.light)
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
                            .padding([.leading, .trailing], 20)
                            .padding([.top], 5)
                        TextView {
                            $0.textColor = theme.colors.primaryText
                            $0.font = bodyFont
                            let userText = $0.text
                            //                    userInput = userText ?? String()
                            // Causes a runtime error
                            // delegate issues - dismiss keyboard, placeholder
                        }
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
                        
                        Spacer()
                    }.background(Color(theme.colors.paperBackground))
                    VStack {
                        Text("\(LocalizedStrings.bottomText) [\(LocalizedStrings.courtesyVanishing)](https://en.wikipedia.org/wiki/Wikipedia:Courtesy_vanishing) \(LocalizedStrings.bottomTextContinuation)")
                            .foregroundColor(Color(theme.colors.secondaryText))
                            .fontWeight(.light)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 120)
                            .font(Font(bodyFont))
                            .padding(20)
                        
                        Spacer()
                        Button(action: {
                            //                    openMailClient()
                            withAnimation(.linear(duration: 0.3)) {
                                showPopUp.toggle() // testing the modal, remove
                            }
                        }, label: {
                            Text(LocalizedStrings.buttonText)
                                .font(Font(titleFont))
                                .foregroundColor(Color(theme.colors.link))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .frame(width: 335, height: 46)
                                .background(Color(theme.colors.paperBackground))
                                .cornerRadius(8)
                                .padding(20)
                        })
                        Spacer()
                    }.background(Color(theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                VanishAccountPopUpAlert(theme:theme, isVisible: $showPopUp)
            }
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
        UIApplication.shared.open(mailtoURL)
    }
    
}

// struct VanishAccountContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        VanishAccountContentView(theme: Theme.black, username: "UserName")
//    }
// }

struct TextView: UIViewRepresentable {
    
    typealias UIViewType = UITextView
    var configuration = { (view: UIViewType) in }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIViewType {
        UIViewType()
    }
    
    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<Self>) {
        configuration(uiView)
    }
}
