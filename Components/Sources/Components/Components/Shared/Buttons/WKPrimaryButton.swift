import Foundation
import SwiftUI

struct WKPrimaryButton: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    
    let title: String
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }, label: {
            Text(title)
                .font(Font(WKFont.for(.boldSubheadline)))
                .foregroundColor(Color(WKColor.white))
        })
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(Color(appEnvironment.theme.link))
        .cornerRadius(8)
    }
}
