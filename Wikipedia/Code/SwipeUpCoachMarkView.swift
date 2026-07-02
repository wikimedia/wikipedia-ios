import UIKit
import Lottie
import WMFComponents

/// A coach-mark overlay that teaches the swipe-up gesture on the Home "For You" tab.
///
/// Displays a looping Lottie animation (dark scrim circle + white hand swiping up) with an
/// instructional caption. The overlay captures all touches until the user performs a single
/// swipe-up gesture, at which point `onDismiss` is called so the host can remove it.
final class SwipeUpCoachMarkView: UIView {

    /// Called once, when the user performs the swipe-up gesture.
    var onDismiss: (() -> Void)?

    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "swipe_up_hand")
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = WMFFont.for(.semiboldHeadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(captionText: String) {
        super.init(frame: .zero)
        captionLabel.text = captionText
        backgroundColor = .clear
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(animationView)
        addSubview(captionLabel)

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 300),
            animationView.heightAnchor.constraint(equalToConstant: 300),

            // Caption sits in the lower portion of the scrim circle, mirroring the reference design.
            captionLabel.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            captionLabel.centerYAnchor.constraint(equalTo: animationView.centerYAnchor, constant: 66),
            captionLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 190)
        ])

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)

        isAccessibilityElement = true
        accessibilityLabel = captionLabel.text
        accessibilityTraits = .staticText
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            animationView.play()
        } else {
            animationView.stop()
        }
    }

    @objc private func handleSwipeUp() {
        onDismiss?()
    }
}
