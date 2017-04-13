protocol PlaceSearchFilterListDelegate: NSObjectProtocol {
    
    func placesSearchFilterListController(_ placesSearchFilterListController: PlaceSearchFilterListController,
                                          didSelectFilterType filterType: PlaceFilterType) -> Void
}

class PlaceSearchFilterListController: UITableViewController {
    
    weak var delegate: PlaceSearchFilterListDelegate!
    
    var currentFilterType: PlaceFilterType = .top {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    init(delegate: PlaceSearchFilterListDelegate) {
        super.init(style: .plain)
        self.delegate = delegate
        self.currentFilterType = .top
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        configureCell(cell: cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let myCell = cell as? PlaceSearchFilterCell else {
            return
        }
        
        if (indexPath.row == 0) {
            myCell.titleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-top-articles")
            myCell.subtitleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-top-articles-count").replacingOccurrences(of: "$1", with: "0")
            
            if (currentFilterType == .top) {
                myCell.iconImageView?.image = #imageLiteral(resourceName: "places-suggestion-top")
            } else {
                myCell.iconImageView?.image = #imageLiteral(resourceName: "places-filter-saved-disabled")
            }

        } else if (indexPath.row == 1) {
            myCell.titleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-saved-articles")
            myCell.subtitleLabel.text = localizedStringForKeyFallingBackOnEnglish("places-filter-saved-articles-count").replacingOccurrences(of: "$1", with: "0")
            
            if (currentFilterType == .saved) {
                myCell.iconImageView?.image = #imageLiteral(resourceName: "places-suggestion-saved")
                
            } else {
                myCell.iconImageView?.image = #imageLiteral(resourceName: "places-filter-saved-disabled")
            }
        }
    }
    
    //MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.row == 0) {
            delegate.placesSearchFilterListController(self, didSelectFilterType: .top)
        } else if (indexPath.row == 1) {
            delegate.placesSearchFilterListController(self, didSelectFilterType: .saved)
        }
    }
}
