import SwiftUI
import WMF

struct VanishAccountPopUpAlertView: View {
    var theme: Theme
    
    @Binding var isVisible: Bool
    @Binding var userInput: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .semibold, size: 18)
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-modal-title", value: "Vanishing request", comment: "Title text fot the vanish request modal")
        static let firstItem = WMFLocalizedString("vanish-modal-item", value: "If you completed your vanishing request, please allow a couple of days for the request to be processed by an administrator.", comment: "Text indicating that the process of vanishing might take days to be completed")
        static let secondItem = WMFLocalizedString("vanish-modal-item-2", value: "If you are unsure if your request went through please check your Mail app", comment: "Text indicating that the user should check if their email was sent in the Mail app used to send the message")
        static let thirdItem = WMFLocalizedString("vanish-modal-item-3", value: "If you have further questions about vanishing please visit", comment: "Text indicating that more infor is in the following link")
        static let linkTitle = WMFLocalizedString("vanishing-link-title", value: "Wikipedia:Courtesy vanishing.", comment: "Courtesy vanishing page title")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(isVisible ? 0.3 : 0).edgesIgnoringSafeArea(.all)
                if isVisible {
                    ScrollView(.vertical, showsIndicators: false) {
                        Spacer()
                            .frame(height: geometry.size.height / 5)
                        VStack(alignment: .center, spacing: 0) {
                            Text(LocalizedStrings.title)
                                .frame(alignment: .center)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(Font(titleFont))
                                .foregroundColor(Color(theme.colors.primaryText))
                                .padding(10)
                            Image("vanish-account-two-tone")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 85, height: 85, alignment: .center)
                            BulletListView(theme: theme)
                                .background(Color(theme.colors.paperBackground))
                                .padding([.top, .leading, .trailing], 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Divider()
                            Button(action: {
                                withAnimation(.linear(duration: 0.3)) {
                                    userInput = ""
                                    isVisible = false
                                }
                            }, label: {
                                Text(CommonStrings.okTitle)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 43, alignment: .center)
                                    .foregroundColor(Color(theme.colors.link))
                                    .font(Font(titleFont))
                            }).buttonStyle(PlainButtonStyle())
                        }
                        .frame(maxWidth: 300)
                        .background(Color(theme.colors.paperBackground))
                        .cornerRadius(14)
                    }
                }
            }.frame(minHeight: geometry.size.height)
        }
    }
}

struct BulletListView: View {
    
    var theme: Theme
    @SwiftUI.State var orientation = UIDeviceOrientation.unknown
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-modal-title", value: "Vanishing request", comment: "Title text fot the vanish request modal")
        static let firstItem = WMFLocalizedString("vanish-modal-item", value: "If you completed your vanishing request, please allow a couple of days for the request to be processed by an administrator.", comment: "Text indicating that the process of vanishing might take days to be completed")
        static let secondItem = WMFLocalizedString("vanish-modal-item-2", value: "If you are unsure if your request went through please check your Mail app", comment: "Text indicating that the user should check if their email was sent in the Mail app used to send the message")
        static let thirdItem = WMFLocalizedString("vanish-modal-item-3", value: "If you have further questions about vanishing please visit Wikipedia:Courtesy vanishing", comment: "Informative text indicating more information is available at a Wikipedia page")
        @available(iOS 15, *)
        static var thirdItemiOS15: AttributedString? = {
            
            let localizedString = WMFLocalizedString("vanish-modal-item-3-ios15", value: "If you have further questions about vanishing please visit %1$@Wikipedia:Courtesy vanishing%2$@%3$@.", comment: "Informative text indicating more information is available at a Wikipedia page, contains link to page. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting.")
            
            let substitutedString = String.localizedStringWithFormat(
                localizedString,
                "[",
                "]",
                "(https://en.wikipedia.org/wiki/Wikipedia:Courtesy_vanishing)"
            )
            
            return try? AttributedString(markdown: substitutedString)
        }()
    }
    
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
    
    var body: some View {
        VStack {
            HStack {
                BulletView(theme: theme, height: 52)
                Text(LocalizedStrings.firstItem)
                    .font(Font(bodyFont))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color(theme.colors.primaryText))
            }
            HStack {
                BulletView(theme: theme, height: 40)
                Text(LocalizedStrings.secondItem)
                    .font(Font(bodyFont))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color(theme.colors.primaryText))
            }
            HStack {
                BulletView(theme: theme, height: 44)
                if #available(iOS 15, *) {
                    if let text = LocalizedStrings.thirdItemiOS15 {
                        Text(text)
                            .font(Font(bodyFont))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(theme.colors.primaryText))
                            .padding(.bottom, 10)
                    } else {
                        Text(LocalizedStrings.thirdItem)
                            .font(Font(bodyFont))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(theme.colors.primaryText))
                            .padding(.bottom, 10)
                    }
                } else {
                    Text(LocalizedStrings.thirdItem)
                        .font(Font(bodyFont))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Color(theme.colors.primaryText))
                        .padding(.bottom, 10)
                }
                
            }
        }
    }
}

struct BulletView: View {
    
    var theme: Theme
    var height: CGFloat
    
    var body: some View {
        VStack {
            Circle()
                .frame(width: 3, height: 3, alignment: .top)
                .foregroundColor(Color(theme.colors.primaryText))
            Spacer()
        }.frame(maxHeight: height, alignment: .leading)
    }
    
}
