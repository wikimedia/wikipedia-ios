import Foundation

/// Allows disabling of Scribble interaction on `UIScribbleInteraction` conforming text views
@available(iOS 14.0, *)
final class ScribbleIgnoringInteractionDelegate: NSObject, UIScribbleInteractionDelegate {
    
    func scribbleInteraction(_ interaction: UIScribbleInteraction, shouldBeginAt location: CGPoint) -> Bool {
        return false
    }

}
