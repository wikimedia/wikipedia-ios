import SwiftUI

struct WMFLargeButtonLoading: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let style: WMFButtonStyleKind
    let title: String
    let icon: UIImage?
    @Binding var isLoading: Bool
    let action: (() -> Void)?

    private var progressTintColor: UIColor {
        switch style {
        case .primary, .glass:
            return WMFColor.white
        case .neutral, .quiet:
            return appEnvironment.theme.link
        }
    }

    var body: some View {
        Button {
            action?()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(
                                tint: Color(uiColor: progressTintColor)
                            )
                        )
                        .scaleEffect(1.1)
                } else {
                    HStack(spacing: 6) {
                        if let icon {
                            Image(uiImage: icon)
                        }
                        Text(title)
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                    }
                }
            }
        }
        .buttonStyle(
            CapsuleButtonStyle(
                kind: style,
                layout: .fill,
                theme: appEnvironment.theme,
                height: 46
            )
        )
        .disabled(isLoading)
    }
}
