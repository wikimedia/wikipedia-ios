import UIKit

protocol PageHistoryComparisonSelectionViewControllerDelegate: AnyObject {
    func pageHistoryComparisonSelectionViewController(_ pageHistoryComparisonSelectionViewController: PageHistoryComparisonSelectionViewController, didTapSelectionButton button: UIButton)
    func pageHistoryComparisonSelectionViewController(_ pageHistoryComparisonSelectionViewController: PageHistoryComparisonSelectionViewController, didTapCompareButton button: UIButton)
}

class PageHistoryComparisonSelectionViewController: UIViewController {
    @IBOutlet weak var firstSelectionButton: AlignedImageButton!
    @IBOutlet weak var secondSelectionButton: AlignedImageButton!
    @IBOutlet private weak var compareButton: UIButton!

    private var theme = Theme.standard

    public weak var delegate: PageHistoryComparisonSelectionViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(button: firstSelectionButton)
        setup(button: secondSelectionButton)
        compareButton.setTitle(CommonStrings.compareTitle, for: .normal)
        compareButton.addTarget(self, action: #selector(performCompareButtonAction(_:)), for: .touchUpInside)
        resetSelectionButtons()
        updateFonts()
    }

    private func setup(button: AlignedImageButton) {
        button.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = theme.colors.paperBackground
        button.imageView?.tintColor = theme.colors.link
        button.setTitleColor(theme.colors.link, for: .normal)
        button.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        button.horizontalSpacing = 10
        button.contentHorizontalAlignment = .leading
        button.leftPadding = 10
        button.rightPadding = 10
        button.addTarget(self, action: #selector(performSelectionButtonAction(_:)), for: .touchUpInside)
    }

    @objc private func performSelectionButtonAction(_ sender: AlignedImageButton) {
        delegate?.pageHistoryComparisonSelectionViewController(self, didTapSelectionButton: sender)
    }

    @objc private func performCompareButtonAction(_ sender: UIButton) {
        delegate?.pageHistoryComparisonSelectionViewController(self, didTapCompareButton: sender)
    }

    private func reset(button: AlignedImageButton?) {
        button?.setTitle(nil, for: .normal)
        button?.setImage(nil, for: .normal)
        button?.backgroundColor = theme.colors.paperBackground
        button?.borderWidth = 0
    }

    public func resetSelectionButtonWithTag(_ tag: Int) {
        assert(0...1 ~= tag, "Unsupported tag")
        reset(button: buttonWithTag(tag))
    }

    public func resetSelectionButtons() {
        reset(button: firstSelectionButton)
        reset(button: secondSelectionButton)
    }

    public func setCompareButtonEnabled(_ enabled: Bool) {
        compareButton.isEnabled = enabled
    }

    private func buttonWithTag(_ tag: Int) -> AlignedImageButton? {
        assert(0...1 ~= tag, "Unsupported tag")
        if tag == 0 {
            return firstSelectionButton
        } else if tag == 1 {
            return secondSelectionButton
        } else {
            return nil
        }
    }

    public func updateSelectionButtonWithTag(_ tag: Int, with themeModel: PageHistoryViewController.SelectionThemeModel, cell: PageHistoryCollectionViewCell) {
        let button = buttonWithTag(tag)
        UIView.performWithoutAnimation {
            button?.setTitle(cell.time, for: .normal)
            button?.setImage(cell.authorImage, for: .normal)
            button?.backgroundColor = themeModel.backgroundColor
            button?.imageView?.tintColor = themeModel.authorColor
            button?.setTitleColor(themeModel.authorColor, for: .normal)
            button?.tintColor = themeModel.authorColor
            button?.borderWidth = 1
            button?.borderColor = themeModel.borderColor
        }
    }

    private func updateFonts() {
        compareButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        firstSelectionButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        secondSelectionButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
    }

}

extension PageHistoryComparisonSelectionViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.midBackground
        compareButton.tintColor = theme.colors.link
    }
}
