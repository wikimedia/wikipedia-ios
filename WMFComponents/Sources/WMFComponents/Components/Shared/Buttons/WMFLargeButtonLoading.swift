import SwiftUI

struct WMFLargeButtonLoading: View {
    
    enum Configuration {
        case primary
        case secondary
    }
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    let configuration: Configuration
    let title: String
    let icon: UIImage?
    @Binding var isLoading: Bool
    let action: (() -> Void)?
    
    private var foregroundColor: UIColor {
        switch configuration {
        case .primary:
            return WMFColor.white
        case .secondary:
            return appEnvironment.theme.link
        }
    }
    
    private var backgroundColor: UIColor {
        switch configuration {
        case .primary:
            return appEnvironment.theme.link
        case .secondary:
            return .clear
        }
    }
    
    var body: some View {
        Button(action: {
            action?()
        }, label: {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(foregroundColor)))
                    .scaleEffect(1.2)
                    .foregroundColor(Color(foregroundColor))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(backgroundColor))
                    .cornerRadius(8)
            } else {
                HStack(alignment: .center, spacing: 6) {
                    if let icon {
                        Image(uiImage: icon)
                    }
                    Text(title)
                        .font(Font(WMFFont.for(.semiboldHeadline)))
                }
                .foregroundColor(Color(foregroundColor))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color(backgroundColor))
                .cornerRadius(8)
            }
        })
    }
}
