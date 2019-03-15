import UIKit

final class WelcomeAnimationViewController: UIViewController {
    let animationView: WelcomeAnimationView
    let position: Position

    init(position: Position, animationView: WelcomeAnimationView) {
        self.position = position
        self.animationView = animationView
        super.init(nibName: nil, bundle: nil)
    }

    enum Position {
        case foreground
        case background
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wmf_addSubviewWithConstraintsToEdges(animationView)
        if position == .background {
            addHorizontalAndVerticalParallax(to: view, amount: 12)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.animate()
    }

    private func addHorizontalAndVerticalParallax(to view: UIView, amount: Float) {
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        view.addMotionEffect(group)
    }
}
