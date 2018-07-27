import UIKit

@objc(WMFPassthroughView)
class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let superTest = super.hitTest(point, with: event)
        if superTest === self {
            return nil
        }
        return superTest
    }
}

@objc(WMFPassthroughAnimatedImageView)
class PassthroughAnimatedImageView: FLAnimatedImageView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let superTest = super.hitTest(point, with: event)
        if superTest === self {
            return nil
        }
        return superTest
    }
}
