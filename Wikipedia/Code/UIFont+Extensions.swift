import Foundation

extension UIFont {

    func lineHeightMultipleToMatch(lineSpacing: CGFloat) -> CGFloat {
        return 1 + lineSpacing / self.lineHeight
    }
}
