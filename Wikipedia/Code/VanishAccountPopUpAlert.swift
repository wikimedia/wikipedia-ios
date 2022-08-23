import SwiftUI
import WMF

struct VanishAccountPopUpAlert: View {
    var theme: Theme
    
    @Binding var isVisible: Bool
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .semibold, size: 18) // review fonts
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-modal-title", value: "Vanish request", comment: "Title text fot the vanish request modal")
        static let bullet1 = WMFLocalizedString("vanish-modal-item", value: "If you completed your vanishing request, please allow a couple of days for the request to be processed by an administrator.", comment: " ")
        static let bullet2 = WMFLocalizedString("vanish-modal-item-2", value: "If you are unsure if your request went through please check your Mail app", comment: "")
        static let bullet3 = WMFLocalizedString("vanish-modal-item-3", value: "If you have further questions about vanishing please visit", comment: " ")
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
                    Image("settings-user")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80, alignment: .center)
                        .foregroundColor(Color(theme.colors.link))
                    Text("\(bullet) \(LocalizedStrings.bullet1)\n \(bullet) \(LocalizedStrings.bullet2). \n\(bullet) \(LocalizedStrings.bullet3) [\(LocalizedStrings.linkTitle)](https://en.wikipedia.org/wiki/Wikipedia:Courtesy_vanishing).")
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
                            .frame(height: 54, alignment: .center)
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
