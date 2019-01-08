class SectionEditorWebView: WKWebViewWithSettableInputViews {
    weak var inputViewsSource: SectionEditorInputViewsSource?

    var theme = Theme.standard

    weak var menuItemsDataSource: SectionEditorMenuItemsDataSource?
    weak var menuItemsDelegate: SectionEditorMenuItemsDelegate?

    // MARK: Input view controller

    // inputViewController is a get-only property
    // so we can't set it the same way we're setting inputAccessoryView
    override var inputViewController: UIInputViewController? {
        return inputViewsSource?.inputViewController
    }

    // MARK: Menu items

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let menuItemsDataSource = menuItemsDataSource else {
            assertionFailure("menuItemsDataSource should be set by now")
            return false
        }
        return menuItemsDataSource.availableMenuActions.contains(action)
    }

    @objc func toggleLink(menuItem: UIMenuItem) {
        menuItemsDelegate?.sectionEditorWebViewDidTapLink(self)
    }

    @objc func toggleTemplate(menuItem: UIMenuItem) {
        menuItemsDelegate?.sectionEditorWebViewDidTapTemplate(self)
    }

    @objc func toggleBoldface(menuItem: UIMenuItem) {
        menuItemsDelegate?.sectionEditorWebViewDidTapBoldface(self)
    }

    @objc func toggleItalics(menuItem: UIMenuItem) {
        menuItemsDelegate?.sectionEditorWebViewDidTapItalics(self)
    }

    @objc func toggleCitation(menuItem: UIMenuItem) {
        menuItemsDelegate?.sectionEditorWebViewDidTapCitation(self)
    }

    override func selectAll(_ sender: Any?) {
        menuItemsDelegate?.sectionEditorWebViewDidTapSelectAll(self)
    }

    // MARK: Input accessory view

    func setInputAccessoryView(_ inputAccessoryView: UIView?) {
        self.inputAccessoryView = inputAccessoryView
        reloadInputViews()
    }

    override func reloadInputViews() {
        themeInputViews(theme: theme)
        super.reloadInputViews()
    }
}

// MARK: Themeable

extension SectionEditorWebView {
    private func themeInputViews(theme: Theme) {
        (inputAccessoryView as? Themeable)?.apply(theme: theme)
        (inputView as? Themeable)?.apply(theme: theme)
    }

    func apply(theme: Theme) {
        self.theme = theme
        scrollView.backgroundColor = theme.colors.baseBackground
        backgroundColor = theme.colors.baseBackground
        themeInputViews(theme: theme)
    }
}
