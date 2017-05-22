protocol PlaceSearchSuggestionControllerDelegate: NSObjectProtocol {
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didSelectSearch search: PlaceSearch)
    func placeSearchSuggestionControllerClearButtonPressed(_ controller: PlaceSearchSuggestionController)
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didDeleteSearch search: PlaceSearch)
}

class PlaceSearchSuggestionController: NSObject, UITableViewDataSource, UITableViewDelegate {
    static let cellReuseIdentifier = "org.wikimedia.places"
    static let headerReuseIdentifier = "org.wikimedia.places.header"
    static let suggestionSection = 0
    static let recentSection = 1
    static let currentStringSection = 2
    static let completionSection = 3
    
    var tableView: UITableView = UITableView() {
        didSet {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: PlaceSearchSuggestionController.cellReuseIdentifier)
            tableView.register(WMFTableHeaderLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: PlaceSearchSuggestionController.headerReuseIdentifier)
            tableView.dataSource = self
            tableView.delegate = self
            tableView.reloadData()
            let footerView = UIView()
            footerView.backgroundColor = UIColor.white
            tableView.tableFooterView = footerView
        }
    }
    
    var searches: [[PlaceSearch]] = [[],[],[],[]]{
        didSet {
            tableView.reloadData()
        }
    }
    
    weak var delegate: PlaceSearchSuggestionControllerDelegate?
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return searches.count
    }
    
    var shouldUseFirstSuggestionAsDefault: Bool {
        return searches[PlaceSearchSuggestionController.suggestionSection].count == 0 && searches[PlaceSearchSuggestionController.completionSection].count > 0
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

        let search = searchForIndexPath(indexPath)
        
        switch search.type {
        case .location:
            cell.imageView?.image = #imageLiteral(resourceName: "places-suggestion-location")
        default:
            cell.imageView?.image = #imageLiteral(resourceName: "places-suggestion-text")
            break
        }
        cell.textLabel?.text = search.localizedDescription
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let search = searchForIndexPath(indexPath)
        delegate?.placeSearchSuggestionController(self, didSelectSearch: search)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard searches[section].count > 0, section < 2, let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlaceSearchSuggestionController.headerReuseIdentifier) as? WMFTableHeaderLabelView else {
            return nil
        }
    
        header.prepareForReuse()
        header.contentView.backgroundColor = .wmf_articleListBackground
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
        guard let header = self.tableView(tableView, viewForHeaderInSection: section) as? WMFTableHeaderLabelView else {
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
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        switch indexPath.section {
        case PlaceSearchSuggestionController.recentSection:
            return [UITableViewRowAction(style: .destructive, title: "Delete", handler: { (action, indexPath) in
                let search = self.searchForIndexPath(indexPath)
                self.delegate?.placeSearchSuggestionController(self, didDeleteSearch: search)
            })]
        default:
            return nil
        }
    }
    
    func clearButtonPressed() {
        delegate?.placeSearchSuggestionControllerClearButtonPressed(self)
    }
    
}
