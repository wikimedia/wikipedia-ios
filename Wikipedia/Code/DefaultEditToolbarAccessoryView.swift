import UIKit

@objc(WMFDefaultEditToolbarAccessoryViewDelegate)
protocol DefaultEditToolbarAccessoryViewDelegate: class {
    func defaultEditToolbarAccessoryViewDidTapTextFormattingButton(_ defaultEditToolbarAccessoryView: DefaultEditToolbarAccessoryView, button: UIButton)
    func defaultEditToolbarAccessoryViewDidTapHeaderFormattingButton(_ defaultEditToolbarAccessoryView: DefaultEditToolbarAccessoryView, button: UIButton)
    func defaultEditToolbarAccessoryViewDidTapAddCitationButton(_ defaultEditToolbarAccessoryView: DefaultEditToolbarAccessoryView, button: UIButton)
    func defaultEditToolbarAccessoryViewDidTapAddLinkButton(_ defaultEditToolbarAccessoryView: DefaultEditToolbarAccessoryView, button: UIButton)
    func defaultEditToolbarAccessoryViewDidTapUnorderedListButton(_ defaultEditToolbarAccessoryView: DefaultEditToolbarAccessoryView, button: UIButton)
    func defaultEditToolbarAccessoryViewDidTapOrderedListButton(_ defaultEditToolbarAccessoryView: DefaultEditToolbarAccessoryView, button: UIButton)
}

@objc(WMFDefaultEditToolbarAccessoryView)
class DefaultEditToolbarAccessoryView: EditToolbarAccessoryView {
    @objc weak var delegate: DefaultEditToolbarAccessoryViewDelegate?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var chevronButton: UIButton!
    @IBOutlet var separatorViews: [UIView] = []

    @objc static func loadFromNib() -> DefaultEditToolbarAccessoryView {
        let nib = UINib(nibName: "DefaultEditToolbarAccessoryView", bundle: Bundle.main)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! DefaultEditToolbarAccessoryView
        return view
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        addTopShadow()
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
        delegate?.defaultEditToolbarAccessoryViewDidTapTextFormattingButton(self, button: sender)
    }

    @objc private func formatHeader(_ sender: UIBarButtonItem) {
    }

    @objc private func addCitation(_ sender: UIBarButtonItem) {
    }

    @objc private func addLink(_ sender: UIBarButtonItem) {
    }

    @objc private func addUnorderedList(_ sender: UIBarButtonItem) {
    }

    @objc private func addOrderedList(_ sender: UIBarButtonItem) {
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

    @IBAction private func revealMoreActions(_ sender: UIButton) {
        let offsetX = scrollView.contentOffset.x
        let actionsType = ActionsType(rawValue: offsetX)
        revealMoreActions(ofType: actionsType, with: sender, animated: true)
    }

    private func revealMoreActions(ofType actionsType: ActionsType, with sender: UIButton, animated: Bool) {
        let transform = CGAffineTransform.identity
        let buttonTransform: () -> Void
        let newOffsetX: CGFloat

        switch actionsType {
        case .default:
            buttonTransform = {
                sender.transform = transform
            }
            newOffsetX = 0
        case .secondary:
            buttonTransform = {
                sender.transform = transform.rotated(by: 180 * CGFloat.pi)
                sender.transform = transform.rotated(by: -1 * CGFloat.pi)
            }
            newOffsetX = stackView.bounds.width / 2
        }

        let scrollViewContentOffsetChange = {
            self.scrollView.setContentOffset(CGPoint(x: newOffsetX , y: 0), animated: false)
        }

        if animated {
            let buttonAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.7, animations: buttonTransform)
            let scrollViewAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .linear, animations: scrollViewContentOffsetChange)

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

    // MARK: Size

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.height + 1)
    }

    // MARK: Shadow

    private func addTopShadow() {
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 10
        layer.shadowOpacity = 1.0
    }

}

extension DefaultEditToolbarAccessoryView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.midBackground
        layer.shadowColor = theme.colors.shadow.cgColor
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
    }
}
