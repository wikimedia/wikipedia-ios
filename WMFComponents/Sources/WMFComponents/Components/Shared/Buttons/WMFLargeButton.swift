import Foundation
import SwiftUI

struct WMFLargeButton: View {
    
    enum Configuration {
        case primary
        case secondary
    }
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    let configuration: Configuration
    let title: String
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
            Text(title)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(foregroundColor))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color(backgroundColor))
                .cornerRadius(8)
        })
    }
}
