extension ArticleViewController: ArticleWebMessageHandling {
    func didRecieve(action: ArticleWebMessagingController.Action) {
        switch action {
        case .setup:
            handlePCSDidFinishInitialSetup()
        case .finalSetup:
            handlePCSDidFinishFinalSetup()
        case .link(let title):
            handleLink(with: title)
        case .leadImage(let source, let width, let height):
            handleLeadImage(source: source, width: width, height: height)
        case .tableOfContents(items: let items):
            handleTableOfContents(items: items)
        case .footerItem(let type):
            handleFooterItem(type: type)
        default:
            break
        }
    }
    
    func handleTableOfContents(items: [TableOfContentsItem]) {
        let titleItem = TableOfContentsItem(id: -1, titleHTML: article.displayTitleHTML, anchor: "", rootItemId: -1, indentationLevel: 0)
        var allItems: [TableOfContentsItem] = [titleItem]
        allItems.append(contentsOf: items)
        tableOfContentsItems = allItems
    }
    
    func handlePCSDidFinishInitialSetup() {
        state = .loaded
        webView.becomeFirstResponder()
        showWIconPopoverIfNecessary()
        loadCompletion?()
    }
    
    func handlePCSDidFinishFinalSetup() {
        footerLoadGroup?.leave()
        markArticleAsViewed()
    }
    
    func handleFooterItem(type: PageContentService.Footer.Menu.Item) {
        switch type {
        case .talkPage:
            break
        default:
            break
        }
    }
    
    func handleLeadImage(source: String, width: Int?, height: Int?) {
        guard leadImageView.image == nil && leadImageView.wmf_imageURLToFetch == nil else {
            return
        }
        guard let leadImageURLToRequest = WMFArticle.imageURL(forTargetImageWidth: traitCollection.wmf_leadImageWidth, fromImageSource: source, withOriginalWidth: width ?? 0) else {
            return
        }
        loadLeadImage(with: leadImageURLToRequest)
    }
    
    func setupFooter() {
        // Always use Configuration.production for related articles
        guard let baseURL = Configuration.production.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: []).url else {
            return
        }
        var menuItems: [PageContentService.Footer.Menu.Item] = [.talkPage, .referenceList, .lastEdited]
        if languageCount > 0 {
            menuItems.append(.languages)
        }
        if article.coordinate != nil {
            menuItems.append(.coordinate)
        }
        messagingController.addFooter(articleURL: articleURL, restAPIBaseURL: baseURL, menuItems: menuItems, languageCount:languageCount, lastModified: nil)
    }
}
