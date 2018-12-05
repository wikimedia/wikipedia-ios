import UIKit

protocol DefaultEditToolbarViewDelegate: class {
    func defaultEditToolbarViewDidTapTextFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapHeaderFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapAddCitationButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapAddLinkButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapUnorderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapOrderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
}

class DefaultEditToolbarView: EditToolbarView {
    weak var delegate: DefaultEditToolbarViewDelegate?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var chevronButton: UIButton!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!

    override func awakeFromNib() {
        super.awakeFromNib()
        chevronButton.imageView?.contentMode = .scaleAspectFit
    }

    private func button(withTitle title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func button(withImage image: UIImage, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: Button actions

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapTextFormattingButton(self, button: sender)
    }

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapHeaderFormattingButton(self, button: sender)
    }

    @objc private func addCitation(_ sender: UIButton) {
    }

    @objc private func addLink(_ sender: UIButton) {
    }

    @objc private func addUnorderedList(_ sender: UIButton) {
    }

    @objc private func addOrderedList(_ sender: UIButton) {
    }

    private enum ActionsType: CGFloat {
        case `default`
        case secondary

        init(rawValue: RawValue) {
            if rawValue == 0 {
                self = .secondary
            } else {
                self = .default
            }
        }
    }

    @IBAction private func revealMoreActionsViaTap(_ gestureRecognizer: UITapGestureRecognizer) {
        revealMoreActions(nil)
    }

    @IBAction private func revealMoreActions(_ sender: UIButton?) {
        let offsetX = scrollView.contentOffset.x
        let actionsType = ActionsType(rawValue: offsetX)
        revealMoreActions(ofType: actionsType, with: sender, animated: true)
    }

    private func revealMoreActions(ofType actionsType: ActionsType, with sender: UIButton?, animated: Bool) {
        let transform = CGAffineTransform.identity
        let buttonTransform: () -> Void
        let newOffsetX: CGFloat

        switch actionsType {
        case .default:
            buttonTransform = {
                sender?.transform = transform
            }
            newOffsetX = 0
        case .secondary:
            buttonTransform = {
                sender?.transform = transform.rotated(by: 180 * CGFloat.pi)
                sender?.transform = transform.rotated(by: -1 * CGFloat.pi)
            }
            newOffsetX = stackView.bounds.width / 2
        }

        let scrollViewContentOffsetChange = {
            self.scrollView.setContentOffset(CGPoint(x: newOffsetX , y: 0), animated: false)
        }

        if animated {
            let buttonAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.7, animations: buttonTransform)
            let scrollViewAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut, animations: scrollViewContentOffsetChange)

            buttonAnimator.startAnimation()
            scrollViewAnimator.startAnimation()
        } else {
            buttonTransform()
            scrollViewContentOffsetChange()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        revealMoreActions(ofType: .default, with: chevronButton, animated: false)
    }

}

extension DefaultEditToolbarView {
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        //
    }
}
