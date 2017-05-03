protocol PlaceSearchFilterListDelegate: NSObjectProtocol {
    
    func placeSearchFilterListController(_ placeSearchFilterListController: PlaceSearchFilterListController,
                                          didSelectFilterType filterType: PlaceFilterType) -> Void
    
    func placeSearchFilterListController(_ placeSearchFilterListController: PlaceSearchFilterListController, countForFilterType: PlaceFilterType) -> Int
    
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
            myCell.titleLabel.text = NSLocalizedString("places-filter-top-articles", value:"Top read", comment:"Title of places search filter that searches top articles")
            myCell.subtitleLabel.text = String.localizedStringWithFormat(WMFLocalizedString("places-filter-top-articles-count", value:"{{PLURAL:%1$d|0=No articles|%1$d article|%1$d articles}}", comment: "Describes how many top articles are found in the top articles filter - %1$d is replaced with the number of articles"), delegate.placeSearchFilterListController(self, countForFilterType: .top))
            myCell.iconImageView?.image = #imageLiteral(resourceName: "places-suggestion-top")
        } else if (indexPath.row == 1) {
            myCell.titleLabel.text = NSLocalizedString("places-filter-saved-articles", value:"Saved articles", comment:"Title of places saerch filter that searches saved articles")
            let savedCount = delegate.placeSearchFilterListController(self, countForFilterType: .saved)
            myCell.subtitleLabel.text =  String.localizedStringWithFormat(WMFLocalizedString("places-filter-saved-articles-count", value:"{{PLURAL:%1$d|0=You have no saved places|%1$d place|%1$d places}} found", comment:"Describes how many saved articles are found in the saved articles filter - %1$d is replaced with the number of articles"), savedCount)
            if (savedCount > 0) {
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
            delegate.placeSearchFilterListController(self, didSelectFilterType: .top)
        } else if (indexPath.row == 1) {
            delegate.placeSearchFilterListController(self, didSelectFilterType: .saved)
        }
    }
}

class PlaceSearchFilterCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}
