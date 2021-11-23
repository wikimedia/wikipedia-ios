import UIKit
import WMF

protocol PlaceSearchSuggestionControllerDelegate: NSObjectProtocol {
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didSelectSearch search: PlaceSearch)
    func placeSearchSuggestionControllerClearButtonPressed(_ controller: PlaceSearchSuggestionController)
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didDeleteSearch search: PlaceSearch)
}

class PlaceSearchSuggestionController: NSObject, UITableViewDataSource, UITableViewDelegate, Themeable {
    fileprivate var theme = Theme.standard
    func apply(theme: Theme) {
        self.theme = theme
        tableView.backgroundColor = theme.colors.baseBackground
        tableView.tableFooterView?.backgroundColor = theme.colors.paperBackground
        tableView.reloadData()
    }
    
    static let cellReuseIdentifier = "org.wikimedia.places"
    static let headerReuseIdentifier = "org.wikimedia.places.header"
    static let suggestionSection = 0
    static let recentSection = 1
    static let currentStringSection = 2
    static let completionSection = 3
    
    var wikipediaLanguageCode: String? = "en"
    var siteURL: URL? = nil {
        didSet {
            wikipediaLanguageCode = siteURL?.wmf_languageCode
        }
    }
    
    var tableView: UITableView = UITableView() {
        didSet {
            tableView.register(PlacesSearchSuggestionTableViewCell.wmf_classNib(), forCellReuseIdentifier: PlaceSearchSuggestionController.cellReuseIdentifier)
            tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: PlaceSearchSuggestionController.headerReuseIdentifier)
            tableView.dataSource = self
            tableView.delegate = self
            tableView.reloadData()
            let footerView = UIView()
            tableView.tableFooterView = footerView
        }
    }
    
    var searches: [[PlaceSearch]] = [[],[],[],[]]{
        didSet {
            tableView.reloadData()
        }
    }
    
    weak var delegate: PlaceSearchSuggestionControllerDelegate?
    
    var navigationBarHider: NavigationBarHider? = nil
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return searches.count
    }
    
    var shouldUseFirstSuggestionAsDefault: Bool {
        return searches[PlaceSearchSuggestionController.suggestionSection].isEmpty && !searches[PlaceSearchSuggestionController.completionSection].isEmpty
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section, shouldUseFirstSuggestionAsDefault) {
        case (PlaceSearchSuggestionController.suggestionSection, true):
            return 1
        case (PlaceSearchSuggestionController.completionSection, true):
            return searches[PlaceSearchSuggestionController.completionSection].count - 1
        default:
            return searches[section].count
        }
    }
    
    func searchForIndexPath(_ indexPath: IndexPath) -> PlaceSearch {
        let search: PlaceSearch
        switch (indexPath.section, shouldUseFirstSuggestionAsDefault) {
        case (PlaceSearchSuggestionController.suggestionSection, true):
            search = searches[PlaceSearchSuggestionController.completionSection][0]
        case (PlaceSearchSuggestionController.completionSection, true):
            search = searches[PlaceSearchSuggestionController.completionSection][indexPath.row+1]
        default:
            search = searches[indexPath.section][indexPath.row]
        }
        return search
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:  PlaceSearchSuggestionController.cellReuseIdentifier, for: indexPath)
        guard let searchSuggestionCell = cell as? PlacesSearchSuggestionTableViewCell else {
            return cell
        }

        let search = searchForIndexPath(indexPath)
        
        switch search.type {
        case .nearby:
            searchSuggestionCell.iconImageView.image = #imageLiteral(resourceName: "places-suggestion-location")
        default:
            searchSuggestionCell.iconImageView.image = search.searchResult != nil ? #imageLiteral(resourceName: "nearby-mini") : #imageLiteral(resourceName: "places-suggestion-text")
            
        }
        searchSuggestionCell.titleLabel.text = search.localizedDescription
        searchSuggestionCell.detailLabel.text = search.searchResult?.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: wikipediaLanguageCode)
        searchSuggestionCell.apply(theme: theme)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let search = searchForIndexPath(indexPath)
        delegate?.placeSearchSuggestionController(self, didSelectSearch: search)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !searches[section].isEmpty, section < 2, let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlaceSearchSuggestionController.headerReuseIdentifier) as? WMFTableHeaderFooterLabelView else {
            return nil
        }
    
        header.prepareForReuse()
        if let ht = header as Themeable? {
            ht.apply(theme: theme)
        }
        header.isLabelVerticallyCentered = true
        switch section {
//        case PlaceSearchSuggestionController.suggestionSection:
//            header.text = WMFLocalizedString("places-search-suggested-searches-header", value:"Suggested searches", comment:"Suggested searches - header for the list of suggested searches")
        case PlaceSearchSuggestionController.recentSection:
            header.isClearButtonHidden = false
            header.addClearButtonTarget(self, selector: #selector(clearButtonPressed))
            header.text = WMFLocalizedString("places-search-recently-searched-header", value:"Recently searched", comment:"Recently searched - header for the list of recently searched items")
            header.clearButton.accessibilityLabel = WMFLocalizedString("places-accessibility-clear-saved-searches", value:"Clear saved searches", comment:"Accessibility hint for clearing saved searches")
        default:
            return nil
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let header = self.tableView(tableView, viewForHeaderInSection: section) as? WMFTableHeaderFooterLabelView else {
            return 0
        }
        let calculatedHeight = header.height(withExpectedWidth: tableView.bounds.size.width)
        return calculatedHeight + 23
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case PlaceSearchSuggestionController.recentSection:
            return true
        default:
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch indexPath.section {
        case PlaceSearchSuggestionController.recentSection:
            let contextItem = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
                let search = self.searchForIndexPath(indexPath)
                self.delegate?.placeSearchSuggestionController(self, didDeleteSearch: search)
            }
            return UISwipeActionsConfiguration(actions: [contextItem])
        default:
            return nil
        }
    }
    
    @objc func clearButtonPressed() {
        delegate?.placeSearchSuggestionControllerClearButtonPressed(self)
    }
    
    
    // MARK - ScrollViewDelegate. Ideally, convert this to a ViewController & remove this code
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBarHider?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        navigationBarHider?.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        navigationBarHider?.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        navigationBarHider?.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        navigationBarHider?.scrollViewDidEndScrollingAnimation(scrollView)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        navigationBarHider?.scrollViewWillScrollToTop(scrollView)
        return true
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        navigationBarHider?.scrollViewDidScrollToTop(scrollView)
    }
}
