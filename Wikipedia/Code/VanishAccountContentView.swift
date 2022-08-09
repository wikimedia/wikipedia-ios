import SwiftUI
import WMF

struct VanishAccountContentView: View {
    @SwiftUI.State var userInput: String = ""
    var action: (() -> Void)?
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-account-title", value: "Vanishing process", comment: "Title for the vanishing process screen")
        static let description = WMFLocalizedString("vanish-account-description", value: "Vanishing is a last resort and should only be used when you wish to stop editing forever and also to hide as many of your past associations as possible.\n\nTo initiate the vanishing process please provide the following:", comment: "Description for the vanishing process")
        static let usernameFieldTitle = WMFLocalizedString("vanish-account-username-field", value: "Username and user page", comment: "Title for the username and userpage form field")
        static let additionalInformationFieldTitle = WMFLocalizedString("vanish-account-additional-information-field", value: "Additional information", comment: "Titl for the additional information form field")
        static let bottomText = WMFLocalizedString("vanish-account-bottom-text", value: "Account deletion on Wikipedia is done by changing your account name to make it so others cannot recognize your contributions in a process called account vanishing. You may use the form below to request a courtesy vanishing. Vanishing does not guarantee complete anonymity or remove contributions to the projects.", comment: "Text") // TODO - check string formatting and link
        static let buttonText = WMFLocalizedString("vanish-account-button-text", value: "Send request", comment: "Text for button on vanish account request screen")
    }
    
    var theme: Theme
    var username: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .bold, size: 18) // review fonts
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 13)
    var body: some View {
        // review all fonts and colors
        
        VStack {
            VStack {
                Text(LocalizedStrings.title)
                    .foregroundColor(.black)
                    .fontWeight(.light)
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
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
                    .padding([.top], 10)
                    .padding([.leading, .trailing], 20)
                Text(username)
                    .foregroundColor(Color(theme.colors.secondaryText))
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
                    .padding([.bottom], 5)
                    .padding([.top], 2)
                    .padding([.leading, .trailing], 20)
                Divider().padding([.leading], 20)
                Text(LocalizedStrings.additionalInformationFieldTitle)
                    .foregroundColor(Color(theme.colors.link))
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
                    .padding([.leading, .trailing], 20)
                    .padding([.top], 5)
                Spacer()
            }.background(Color(theme.colors.paperBackground))
            VStack {
                Text(LocalizedStrings.bottomText)
                    .foregroundColor(Color(theme.colors.secondaryText))
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(Font(bodyFont))
                    .padding(20)
                
                Spacer()
                Button(action: {
                    action?()
                }, label: {
                    Text(LocalizedStrings.buttonText)
                        .font(Font(titleFont))
                        .foregroundColor(Color(theme.colors.link))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(width: 335, height: 46)
                        .background(Color(theme.colors.paperBackground))
                        .cornerRadius(8)
                        .padding()
                })
                Spacer()
            }.background(Color(theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
        }
        
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
