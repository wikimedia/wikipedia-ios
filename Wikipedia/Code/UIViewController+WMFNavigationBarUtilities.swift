import UIKit

extension UIView {
    // TODO: make a static func?
    @objc public func wmf_addBottomShadow(with theme: Theme) { // theme is intentionally ignored for now
        // Setup extended navigation bar
        //   Borrowed from https://developer.apple.com/library/content/samplecode/NavBar/Introduction/Intro.html
  
        guard let bgColor = backgroundColor else {
            assertionFailure("Could not get background color of view")
            return
        }
        assert(bgColor != UIColor.clear, "Background color must not be clear")
        
        shadowOffset = CGSize(width: 0, height: CGFloat(1) / traitCollection.displayScale)
        shadowRadius = 0
        shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        shadowOpacity = 0.25
    }
}
