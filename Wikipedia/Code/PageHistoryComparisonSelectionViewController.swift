import WMFComponents

protocol PageHistoryComparisonSelectionViewControllerDelegate: AnyObject {
    func pageHistoryComparisonSelectionViewController(_ pageHistoryComparisonSelectionViewController: PageHistoryComparisonSelectionViewController, selectionOrder: SelectionOrder)
    func pageHistoryComparisonSelectionViewControllerDidTapCompare(_ pageHistoryComparisonSelectionViewController: PageHistoryComparisonSelectionViewController)
}

class PageHistoryComparisonSelectionViewController: UIViewController {
    @IBOutlet private weak var firstSelectionButton: AlignedImageButton!
    @IBOutlet private weak var secondSelectionButton: AlignedImageButton!
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
        button.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        button.horizontalSpacing = 10
        button.contentHorizontalAlignment = .leading
        button.leftPadding = 10
        button.rightPadding = 10
        button.addTarget(self, action: #selector(performSelectionButtonAction(_:)), for: .touchUpInside)
    }

    @objc private func performSelectionButtonAction(_ sender: AlignedImageButton) {
        guard let selectionOrder = SelectionOrder(rawValue: sender.tag) else {
            return
        }
        delegate?.pageHistoryComparisonSelectionViewController(self, selectionOrder: selectionOrder)
    }

    @objc private func performCompareButtonAction(_ sender: UIButton) {
        delegate?.pageHistoryComparisonSelectionViewControllerDidTapCompare(self)
    }

    private func reset(button: AlignedImageButton?) {
        button?.setTitle(nil, for: .normal)
        button?.setImage(nil, for: .normal)
        button?.backgroundColor = theme.colors.paperBackground
        button?.borderWidth = 1
        // themeTODO: define a semantic color for this instead of checking isDark
        button?.borderColor = theme.isDark ? WMFColor.gray300 : theme.colors.border
    }

    public func resetSelectionButton(_ selectionOrder: SelectionOrder) {
        reset(button: button(selectionOrder))
    }

    public func resetSelectionButtons() {
        reset(button: firstSelectionButton)
        reset(button: secondSelectionButton)
    }

    public func setCompareButtonEnabled(_ enabled: Bool) {
        compareButton.isEnabled = enabled
    }

    private func button(_ selectionOrder: SelectionOrder) -> AlignedImageButton? {
        switch selectionOrder {
        case .first:
            return firstSelectionButton
        case .second:
            return secondSelectionButton
        }
    }

    public func updateSelectionButton(_ selectionOrder: SelectionOrder, with themeModel: PageHistoryViewController.SelectionThemeModel, cell: PageHistoryCollectionViewCell) {
        let button = self.button(selectionOrder)
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
        compareButton.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        firstSelectionButton.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        secondSelectionButton.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
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
