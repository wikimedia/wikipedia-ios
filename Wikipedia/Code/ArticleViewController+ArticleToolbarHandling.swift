import WMFComponents
import WMFData

extension ArticleViewController: ArticleToolbarHandling {
    var navigationToolbar: UIToolbar? {
        return navigationController?.toolbar
    }
    
    func updateToolbarItems() {
        guard let toolbarController else { return }
        if TabBarSpike.isEnabled {
            toolbarAccessoryView.setItems(toolbarController.currentItems, inlineItems: [
                toolbarController.saveButton,
                toolbarController.findInPageButton,
                toolbarController.themeButton,
                toolbarController.moreButton
            ])
        } else {
            self.toolbarItems = toolbarController.currentItems
        }
    }

    // MARK: - SPIKE: article toolbar in the tab bar bottom accessory

    func installToolbarAccessory() {
        guard #available(iOS 26.0, *), TabBarSpike.isEnabled, let tabBarController else { return }
        if (tabBarController.bottomAccessory?.contentView as? ArticleToolbarAccessoryView) !== toolbarAccessoryView {
            toolbarAccessoryView.removeFromSuperview()
            tabBarController.setBottomAccessory(UITabAccessory(contentView: toolbarAccessoryView), animated: true)
        }
        setContentScrollView(webView.scrollView, for: .bottom)
    }

    func removeToolbarAccessory() {
        guard #available(iOS 26.0, *), TabBarSpike.isEnabled, let tabBarController else { return }
        if (tabBarController.bottomAccessory?.contentView as? ArticleToolbarAccessoryView) === toolbarAccessoryView {
            tabBarController.setBottomAccessory(nil, animated: true)
        }
    }
    
    func backInTab(article: WMFData.WMFArticleTabsDataController.WMFArticle, controller: ArticleToolbarController) {
        guard let navigationController,
              let siteURL = article.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: article.title),
              let tabIdentifier = coordinator?.tabIdentifier,
              let tabItemIdentifier = article.identifier else {
            return
        }
        
        let identifiers = WMFArticleTabsDataController.Identifiers(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, needsAnimation: false, source: .undefined, tabConfig: .adjacentArticleInTab(identifiers))
        articleCoordinator.start()
    }
    
    func forwardInTab(article: WMFData.WMFArticleTabsDataController.WMFArticle, controller: ArticleToolbarController) {
        guard let navigationController,
              let siteURL = article.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: article.title),
              let tabIdentifier = coordinator?.tabIdentifier,
              let tabItemIdentifier = article.identifier else {
            return
        }
        
        let identifiers = WMFArticleTabsDataController.Identifiers(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, needsAnimation: false, source: .undefined, tabConfig: .adjacentArticleInTab(identifiers))
        articleCoordinator.start()
    }
    
    
    func showTableOfContents(from controller: ArticleToolbarController) {
        showTableOfContents()
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarTOC)
    }
    
    func hideTableOfContents(from controller: ArticleToolbarController) {
        hideTableOfContents()
    }
    
    var isTableOfContentsVisible: Bool {
        return tableOfContentsController.viewController.displayMode == .inline && tableOfContentsController.viewController.isVisible
    }
    
    func toolbarWasTouched(from controller: ArticleToolbarController) {
        skipSemanticSearchFeedback(reason: .startedActivity)
    }

    func toggleSave(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSave)
        let isSaved = dataStore.savedPageList.toggleSavedPage(for: articleURL)
        if isSaved {
            readingListsFunnel.logArticleSaveInCurrentArticle(articleURL)
            NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSaveSuccess)
        } else {
            readingListsFunnel.logArticleUnsaveInCurrentArticle(articleURL)
        }
    }
    
    func showThemePopover(from controller: ArticleToolbarController) {
        themesPresenter?.showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarAppearence)
    }
    
    func saveButtonWasLongPressed(from controller: ArticleToolbarController) {
        let addArticlesToReadingListVC = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        let navigationController = WMFComponentNavigationController(rootViewController: addArticlesToReadingListVC, modalPresentationStyle: .overFullScreen)
        present(navigationController, animated: true)
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSave)
    }
    
    func showLanguagePicker(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarLang)
        showLanguages()
    }
    
    func share(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarShare)
        shareArticle()
    }
    
    func showFindInPage(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSearch)
        showFindInPage()
    }
    
    func showRevisionHistory(from controller: ArticleToolbarController) {
        showEditHistory()
    }
    
    func watch(from controller: ArticleToolbarController) {
        watch()
    }
    
    func unwatch(from controller: ArticleToolbarController) {
        unwatch()
    }
    
    func showArticleTalkPage(from controller: ArticleToolbarController) {
        showTalkPage()
    }
    
    func editArticle(from controller: ArticleToolbarController) {
        showEditorForFullSource()
    }
    
}

// MARK: - SPIKE: tab bar + bottom accessory

enum TabBarSpike {
    /// iPhone on iOS 26+: keep the tab bar in articles and put the article toolbar in the bottom accessory.
    static var isEnabled: Bool {
        guard #available(iOS 26.0, *) else { return false }
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// When true, the minimized (inline) accessory keeps all toolbar items, to measure the space.
    static let showAllItemsInline = false
}

final class ArticleToolbarAccessoryView: UIView {
    private let stackView = UIStackView()
    private var inlineViews: [UIView] = []
    private var minimumSizeConstraints: [NSLayoutConstraint] = []
    private let minimumTapTargetSize: CGFloat = 44

    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            // 8pt, not 16pt: the minimized accessory on iPhone SE is 207pt wide, and 4 items need 4 x 44pt.
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        if #available(iOS 26.0, *) {
            registerForTraitChanges([UITraitTabAccessoryEnvironment.self]) { (view: ArticleToolbarAccessoryView, _: UITraitCollection) in
                view.updateVisibleItems()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItems(_ items: [UIBarButtonItem], inlineItems: [UIBarButtonItem]) {
        NSLayoutConstraint.deactivate(minimumSizeConstraints)
        minimumSizeConstraints = []
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let views = items.compactMap(\.customView)
        for view in views {
            stackView.addArrangedSubview(view)
            minimumSizeConstraints.append(view.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumTapTargetSize))
            minimumSizeConstraints.append(view.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumTapTargetSize))
        }
        NSLayoutConstraint.activate(minimumSizeConstraints)
        inlineViews = inlineItems.compactMap(\.customView)
        updateVisibleItems()
    }

    private func updateVisibleItems() {
        guard #available(iOS 26.0, *) else { return }
        let isInline = traitCollection.tabAccessoryEnvironment == .inline
        for view in stackView.arrangedSubviews {
            view.isHidden = isInline && !TabBarSpike.showAllItemsInline && !inlineViews.contains(view)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard #available(iOS 26.0, *) else { return }
        let visible = stackView.arrangedSubviews.filter { !$0.isHidden }
        let widths = visible.map { Int($0.bounds.width) }
        let heights = visible.map { Int($0.bounds.height) }
        let mode = traitCollection.tabAccessoryEnvironment == .inline ? "inline" : "regular"
        print("[TabBarSpike] accessory \(mode) width=\(Int(bounds.width)) height=\(Int(bounds.height)) items=\(visible.count) itemWidths=\(widths) itemHeights=\(heights) spacing=\(Int(stackView.bounds.width) - widths.reduce(0, +))")
    }
}
