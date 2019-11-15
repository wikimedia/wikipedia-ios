import Foundation

extension UIFont {
    func lineSpacingToMatch(lineHeightMultiple: CGFloat) -> CGFloat {
        return self.lineHeight * (lineHeightMultiple - 1)
    }

    func lineHeightMultipleToMatch(lineSpacing: CGFloat) -> CGFloat {
        return 1 + lineSpacing / self.lineHeight
    }
}
