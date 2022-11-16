import Foundation

/// Allows disabling of Scribble interaction on `UIScribbleInteraction` conforming text views
final class ScribbleIgnoringInteractionDelegate: NSObject, UIScribbleInteractionDelegate {
    
    func scribbleInteraction(_ interaction: UIScribbleInteraction, shouldBeginAt location: CGPoint) -> Bool {
        return false
    }

}
