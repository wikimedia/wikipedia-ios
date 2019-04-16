import UIKit

public extension UIView {
    @objc func wmf_addBottomShadow(with theme: Theme) {
        //   Borrowed from https://developer.apple.com/library/content/samplecode/NavBar/Introduction/Intro.html
  
        guard let bgColor = backgroundColor else {
            assertionFailure("Could not get background color of view")
            return
        }
        assert(bgColor != UIColor.clear, "Background color must not be clear")
        
        layer.shadowOffset = CGSize(width: 0, height: CGFloat(1) / traitCollection.displayScale)
        layer.shadowRadius = 0
        layer.shadowColor = theme.colors.shadow.cgColor
        layer.shadowOpacity = 0.25
    }
}
