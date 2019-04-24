import UIKit

class DefaultEditToolbarView: EditToolbarView {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var chevronButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        chevronButton.imageView?.contentMode = .scaleAspectFit
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        chevronButton.isAccessibilityElement = false
    }

    // MARK: Button actions

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTextFormatting()
    }

    @IBAction private func formatTextStyle(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTextStyleFormatting()
    }

    @IBAction private func toggleCitation(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapReference()
    }

    @IBAction private func toggleLink(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapLink()
    }

    @IBAction private func toggleUnorderedList(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapUnorderedList()
    }

    @IBAction private func toggleOrderedList(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapOrderedList()
    }

    @IBAction private func decreaseIndentation(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapDecreaseIndent()
    }

    @IBAction private func increaseIndentation(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapIncreaseIndent()
    }

    @IBAction private func moveCursorUp(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapCursorUp()
    }

    @IBAction private func moveCursorDown(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapCursorDown()
    }

    @IBAction private func moveCursorLeft(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapCursorLeft()
    }

    @IBAction private func moveCursorRight(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapCursorRight()
    }

    @IBAction private func toggleTemplate(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTemplate()
    }

    @IBAction private func showFindInPage(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapFindInPage()
    }

    @IBAction private func insertMedia(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapMediaInsert()
    }

    private enum ActionsType: CGFloat {
        case `default`
        case secondary

        static func visible(rawValue: RawValue) -> ActionsType {
            if rawValue == 0 {
                return .default
            } else {
                return .secondary
            }
        }

        static func next(rawValue: RawValue) -> ActionsType {
            if rawValue == 0 {
                return .secondary
            } else {
                return .default
            }
        }
    }

    @IBAction private func revealMoreActions(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let offsetX = scrollView.contentOffset.x
        let actionsType = ActionsType.next(rawValue: offsetX)
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
            let buttonAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.7, animations: buttonTransform)
            let scrollViewAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: scrollViewContentOffsetChange)

            buttonAnimator.startAnimation()
            scrollViewAnimator.startAnimation()
        } else {
            buttonTransform()
            scrollViewContentOffsetChange()
        }
    }
}
