import SwiftUI
import WMF

struct VanishAccountPopUpAlert: View {
    var theme: Theme
    
    @Binding var isVisible: Bool
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .semibold, size: 18) // review fonts
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-modal-title", value: "Vanish request", comment: "Title text fot the vanish request modal")
        static let firstItem = WMFLocalizedString("vanish-modal-item", value: "If you completed your vanishing request, please allow a couple of days for the request to be processed by an administrator.", comment: "Text indicating that the process of vanishing might take days to be completed")
        static let secondItem = WMFLocalizedString("vanish-modal-item-2", value: "If you are unsure if your request went through please check your Mail app", comment: "Text indicating that the user should check if their email was sent in the Mail app used to send the message")
        static let thirdItem = WMFLocalizedString("vanish-modal-item-3", value: "If you have further questions about vanishing please visit", comment: "Text indicating that more infor is in the following link")
        static let linkTitle = WMFLocalizedString("vanishing-link-title", value: "Wikipedia:Courtesy vanishing", comment: "Courtesy vanishing page title")
    }

    var body: some View {
        let bullet = "\u{2022}"
        ZStack {
            if isVisible {
                Color.black.opacity(isVisible ? 0.3 : 0).edgesIgnoringSafeArea(.all)
                VStack(alignment: .center, spacing: 0) {
                    Text(LocalizedStrings.title)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45, alignment: .center)
                        .font(Font(titleFont))
                        .foregroundColor(Color(theme.colors.primaryText))
                        .padding(10)
                    Image("vanish-account-2")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 85, height: 85, alignment: .center)
                    Text("\(bullet) \(LocalizedStrings.firstItem)\n \(bullet) \(LocalizedStrings.secondItem). \n\(bullet) \(LocalizedStrings.thirdItem) [\(LocalizedStrings.linkTitle)](https://en.wikipedia.org/wiki/Wikipedia:Courtesy_vanishing).")
                    .multilineTextAlignment(.leading)
                    .font(Font(bodyFont))
                    .padding(25)
                    .foregroundColor(Color(theme.colors.primaryText))
                    Divider()
                    Button(action: {
                        withAnimation(.linear(duration: 0.3)) {
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
    }
}
