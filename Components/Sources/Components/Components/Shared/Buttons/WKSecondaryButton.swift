import SwiftUI

struct WKSecondaryButton: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    
    let title: String
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }, label: {
            Text(title)
                .font(Font(WKFont.for(.boldSubheadline)))
                .foregroundColor(Color(appEnvironment.theme.link))
        })
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(Color(appEnvironment.theme.paperBackground))
        .cornerRadius(8)
    }
}
