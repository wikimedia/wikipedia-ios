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
    let forceBackgroundColor: UIColor?
    let action: (() -> Void)?
    
    init(appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, configuration: Configuration, title: String, forceBackgroundColor: UIColor? = nil, action: (() -> Void)?) {
        self.appEnvironment = appEnvironment
        self.configuration = configuration
        self.title = title
        self.forceBackgroundColor = forceBackgroundColor
        self.action = action
    }
    
    private var foregroundColor: UIColor {
        switch configuration {
        case .primary:
            return WMFColor.white
        case .secondary:
            return appEnvironment.theme.link
        }
    }
    
    private var backgroundColor: UIColor {
        
        if let forceBackgroundColor {
            return forceBackgroundColor
        }
        
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
