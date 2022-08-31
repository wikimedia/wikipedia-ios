import SwiftUI
import WMF

struct VanishAccountPopUpAlertView: View {
    var theme: Theme
    
    @Binding var isVisible: Bool
    @Binding var userInput: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .semibold, size: 18)
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
    private let boldFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .bold, size: 18)
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-modal-title", value: "Vanishing request", comment: "Title text fot the vanish request modal")
        static let learnMoreButtonText = CommonStrings.learnMoreButtonText
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(isVisible ? 0.3 : 0).edgesIgnoringSafeArea(.all)
                if isVisible {
                    ScrollView(.vertical, showsIndicators: false) {
                        Spacer()
                            .frame(height: getSpacerHeight(height: geometry.size.height))
                        VStack(alignment: .center, spacing: 0) {
                            Text(LocalizedStrings.title)
                                .frame(alignment: .center)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(Font(titleFont))
                                .foregroundColor(Color(theme.colors.primaryText))
                                .padding(20)
                            Spacer()
                            Image("vanish-account-two-tone")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 85, height: 85, alignment: .center)
                            BulletListView(theme: theme)
                                .background(Color(theme.colors.paperBackground))
                                .padding([.top, .leading, .trailing], 20)
                                .frame(maxWidth: .infinity, minHeight: 240, alignment: .leading)
                            if #unavailable(iOS 15) {
                                HStack {
                                    Button(action: {
                                        goToVanishPage()
                                    }, label: {
                                        Text(LocalizedStrings.learnMoreButtonText)
                                            .font(Font(bodyFont))
                                            .foregroundColor(Color(theme.colors.link))
                                            .frame(height: 25, alignment: .center)
                                            .background(Color(theme.colors.paperBackground))
                                    })
                                    .padding(.bottom, 20)
                                    .frame(height: 25, alignment: .center)
                                    Spacer()
                                }
                                .padding(30)
                                .frame(maxHeight: 25)
                            }
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
                                    .font(Font(boldFont))
                            }).buttonStyle(PlainButtonStyle())
                                .frame(height: 43)
                        }
                        .frame(width: 300)
                        .frame(minHeight: 470)
                        .background(Color(theme.colors.paperBackground))
                        .cornerRadius(14)
                    }
                    Spacer()
                }
            }.frame(minHeight: geometry.size.height)
        }
    }
    
    func goToVanishPage() {
        if let url = URL(string: "https://meta.wikimedia.org/wiki/Right_to_vanish") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func getSpacerHeight(height: CGFloat) -> CGFloat {
        if height > 470 {
            return (height - 470) / 2
        }
            return height / 5
    }
}

struct BulletListView: View {
    
    var theme: Theme
    @SwiftUI.State var orientation = UIDeviceOrientation.unknown
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-modal-title", value: "Vanishing request", comment: "Title text fot the vanish request modal")
        static let firstItem = WMFLocalizedString("vanish-modal-item", value: "If you completed your vanishing request, please allow a couple of days for the request to be processed by an administrator", comment: "Text indicating that the process of vanishing might take days to be completed")
        static let secondItem = WMFLocalizedString("vanish-modal-item-2", value: "If you are unsure if your request went through please check your Mail app", comment: "Text indicating that the user should check if their email was sent in the Mail app used to send the message")
        static let thirdItem = WMFLocalizedString("vanish-modal-item-3", value: "If you have further questions about vanishing please visit Meta:Right_to_vanish", comment: "Informative text indicating more information is available at the Meta-wiki page Right to vanish")
        @available(iOS 15, *)
        static var thirdItemiOS15: AttributedString? = {
            
            let localizedString = WMFLocalizedString("vanish-modal-item-3-ios15", value: "If you have further questions about vanishing please visit %1$@Meta:Right_to_vanish%2$@%3$@", comment: "Informative text indicating more information is available at a Wikipedia page, contains link to page. The parameters do not require translation, as they are used for markdown formatting. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting")
            
            let substitutedString = String.localizedStringWithFormat(
                localizedString,
                "[",
                "]",
                "(https://meta.wikimedia.org/wiki/Right_to_vanish)"
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
                    .fixedSize(horizontal: false, vertical: true)
                    .font(Font(bodyFont))
                    .frame(maxWidth: .infinity, minHeight: 75, alignment: .leading)
                    .foregroundColor(Color(theme.colors.primaryText))
            }
            HStack {
                BulletView(theme: theme, height: 40)
                Text(LocalizedStrings.secondItem)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(Font(bodyFont))
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                    .foregroundColor(Color(theme.colors.primaryText))
            }
            HStack {
                BulletView(theme: theme, height: 44)
                if #available(iOS 15, *) {
                    if let text = LocalizedStrings.thirdItemiOS15 {
                        Text(text)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font(bodyFont))
                            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                            .foregroundColor(Color(theme.colors.primaryText))
                            .padding(.bottom, 10)
                    } else {
                        Text(LocalizedStrings.thirdItem)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(Font(bodyFont))
                            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                            .foregroundColor(Color(theme.colors.primaryText))
                            .padding(.bottom, 10)
                    }
                } else {
                    Text(LocalizedStrings.thirdItem)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(Font(bodyFont))
                        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
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
