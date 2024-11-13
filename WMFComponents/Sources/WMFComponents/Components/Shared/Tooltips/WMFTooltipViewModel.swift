import Foundation
import UIKit

public final class WMFTooltipViewModel {
    
    public struct LocalizedStrings {
        let title: String
        let body: String
        let buttonTitle: String
        
        public init(title: String, body: String, buttonTitle: String) {
            self.title = title
            self.body = body
            self.buttonTitle = buttonTitle
        }
    }
    
    let localizedStrings: LocalizedStrings
    let buttonNeedsDisclosure: Bool
    let sourceView: UIView
    let sourceRect: CGRect
    let permittedArrowDirections: UIPopoverArrowDirection
    var buttonAction: (() -> Void)?
    
    public init(localizedStrings: LocalizedStrings, buttonNeedsDisclosure: Bool, sourceView: UIView, sourceRect: CGRect, permittedArrowDirections: UIPopoverArrowDirection = .any, buttonAction: (() -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.buttonNeedsDisclosure = buttonNeedsDisclosure
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.permittedArrowDirections = permittedArrowDirections
        self.buttonAction = buttonAction
    }
}
