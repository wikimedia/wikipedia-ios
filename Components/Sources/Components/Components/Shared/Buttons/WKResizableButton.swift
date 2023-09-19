import SwiftUI

struct WKResizableButton: View {

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
                .padding(12)
        })
        .frame(height: 46)
        .background(Color(appEnvironment.theme.baseBackground))
        .cornerRadius(8)
    }
}
