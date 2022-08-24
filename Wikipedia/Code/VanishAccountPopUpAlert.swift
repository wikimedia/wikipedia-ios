import SwiftUI
import WMF

struct VanishAccountPopUpAlert: View {
    var theme: Theme
    
    @Binding var isVisible: Bool
    @Binding var userInput: String
    
    private let titleFont = UIFont.wmf_scaledSystemFont(forTextStyle: .headline, weight: .semibold, size: 18)
    
    @SwiftUI.State private var thisWidth: CGFloat = 300
    @SwiftUI.State private var orientation = UIDeviceOrientation.unknown
    
    enum LocalizedStrings {
        static let title = WMFLocalizedString("vanish-modal-title", value: "Vanishing request", comment: "Title text fot the vanish request modal")
        static let firstItem = WMFLocalizedString("vanish-modal-item", value: "If you completed your vanishing request, please allow a couple of days for the request to be processed by an administrator.", comment: "Text indicating that the process of vanishing might take days to be completed")
        static let secondItem = WMFLocalizedString("vanish-modal-item-2", value: "If you are unsure if your request went through please check your Mail app", comment: "Text indicating that the user should check if their email was sent in the Mail app used to send the message")
        static let thirdItem = WMFLocalizedString("vanish-modal-item-3", value: "If you have further questions about vanishing please visit", comment: "Text indicating that more infor is in the following link")
        static let linkTitle = WMFLocalizedString("vanishing-link-title", value: "Wikipedia:Courtesy vanishing.", comment: "Courtesy vanishing page title")
    }
    
    var body: some View {
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
                .frame(maxWidth: thisWidth)
                .background(Color(theme.colors.paperBackground))
                .cornerRadius(14)
                .onRotate { newOr in
                    orientation = newOr
                    updateOrientation()
                }
            }
        }
    }
    
    private func updateOrientation() {
        if orientation.isPortrait {
            thisWidth = 300
        } else {
            thisWidth = 800
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
        static let thirdItem = WMFLocalizedString("vanish-modal-item-3", value: "If you have further questions about vanishing please visit", comment: "Text indicating that more infor is in the following link")
        static let linkTitle = WMFLocalizedString("vanishing-link-title", value: "Wikipedia:Courtesy vanishing", comment: "Courtesy vanishing page title")
    }
    
    private let bodyFont = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .regular, size: 15)
    
    var body: some View {
        VStack {
            HStack {
                BulletView(theme: theme, height: updateHeight(height: 52))
                Text(LocalizedStrings.firstItem)
                    .font(Font(bodyFont))
                    .frame(maxWidth: .infinity, minHeight: updateHeight(height: 90), alignment: .leading)
            }
            HStack {
                BulletView(theme: theme, height: updateHeight(height: 40))
                Text(LocalizedStrings.secondItem)
                    .font(Font(bodyFont))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                BulletView(theme: theme, height: updateHeight(height: 44))
                Text("\(LocalizedStrings.thirdItem) [\(LocalizedStrings.linkTitle)](https://en.wikipedia.org/wiki/Wikipedia:Courtesy_vanishing)")
                    .font(Font(bodyFont))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
            }
        }.onRotate { newOr in
            orientation = newOr
        }
    }
    
    func updateHeight(height: CGFloat) -> CGFloat {
        if orientation.isLandscape {
            return height - 30
        } else {
            return height
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

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
