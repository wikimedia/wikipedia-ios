import Foundation
import SwiftUI

struct WKLargeButton: View {
    
    enum Configuration {
        case primary
    }
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    
    let configuration: Configuration
    let title: String
    let action: (() -> Void)?
    
    private var foregroundColor: UIColor {
        switch configuration {
        case .primary:
            return WKColor.white
        }
    }
    
    private var backgroundColor: UIColor {
        switch configuration {
        case .primary:
            return appEnvironment.theme.link
        }
    }
    
    var body: some View {
        Button(action: {
            action?()
        }, label: {
            Text(title)
                .font(Font(WKFont.for(.boldSubheadline)))
                .foregroundColor(Color(foregroundColor))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color(backgroundColor))
                .cornerRadius(8)
        })
    }
}
