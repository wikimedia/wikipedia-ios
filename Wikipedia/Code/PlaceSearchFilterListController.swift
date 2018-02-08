protocol PlaceSearchFilterListDelegate: NSObjectProtocol {
    
    func placeSearchFilterListController(_ placeSearchFilterListController: PlaceSearchFilterListController,
                                          didSelectFilterType filterType: PlaceFilterType) -> Void
    
    func placeSearchFilterListController(_ placeSearchFilterListController: PlaceSearchFilterListController, countForFilterType: PlaceFilterType) -> Int
    
}

@objc(WMFPlaceSearchFilterListController)
class PlaceSearchFilterListController: UITableViewController, Themeable {
    fileprivate var theme: Theme = Theme.standard
    
    static var savedArticlesFilterLocalizedTitle = WMFLocalizedString("places-filter-saved-articles", value:"Saved articles", comment:"Title of places search filter that searches saved articles")
    static var topArticlesFilterLocalizedTitle = WMFLocalizedString("places-filter-top-articles", value:"Top read", comment:"Title of places search filter that searches top articles")
    
    weak var delegate: PlaceSearchFilterListDelegate?
    
    var currentFilterType: PlaceFilterType = .top {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    public func preferredHeight(for width: CGFloat) -> CGFloat {
        return 128 // this should be dynamically calculated if/when this view supports dynamic type
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentFilterType = .top
        apply(theme: theme)
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
        guard let delegate = delegate, let myCell = cell as? PlaceSearchFilterCell else {
            return
        }
        
        myCell.apply(theme: theme)
        
        if (indexPath.row == 0) {
            myCell.titleLabel.text = PlaceSearchFilterListController.topArticlesFilterLocalizedTitle
            myCell.subtitleLabel.text = String.localizedStringWithFormat(CommonStrings.articleCountFormat, delegate.placeSearchFilterListController(self, countForFilterType: .top))
            myCell.iconImageView?.image = #imageLiteral(resourceName: "places-filter-top")
            myCell.iconImageView?.tintColor = theme.colors.accent
        } else if (indexPath.row == 1) {
            myCell.titleLabel.text = PlaceSearchFilterListController.savedArticlesFilterLocalizedTitle
            let savedCount = delegate.placeSearchFilterListController(self, countForFilterType: .saved)
            if (savedCount > 0) {
                myCell.subtitleLabel.text =  String.localizedStringWithFormat(WMFLocalizedString("places-filter-saved-articles-count", value:"{{PLURAL:%1$d|%1$d place|%1$d places}} found", comment:"Describes how many saved articles are found in the saved articles filter - %1$d is replaced with the number of articles"), delegate.placeSearchFilterListController(self, countForFilterType: .saved))
                myCell.iconImageView?.image = #imageLiteral(resourceName: "places-filter-saved")
                myCell.iconImageView?.tintColor = theme.colors.accent
            } else {
                myCell.subtitleLabel.text = WMFLocalizedString("places-filter-no-saved-places", value:"You have no saved places", comment:"Explains that you don't have any saved places")
                myCell.iconImageView?.image = #imageLiteral(resourceName: "places-filter-saved")
                myCell.iconImageView?.tintColor = theme.colors.secondaryText
            }
        }
    }
    
    //MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let delegate = delegate else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.row == 0) {
            delegate.placeSearchFilterListController(self, didSelectFilterType: .top)
        } else if (indexPath.row == 1) {
            delegate.placeSearchFilterListController(self, didSelectFilterType: .saved)
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.chromeBackground
        tableView.reloadData()
    }
}

class PlaceSearchFilterCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = UIView()
        selectedBackgroundView = UIView()
    }
}

extension PlaceSearchFilterCell: Themeable {
    func apply(theme: Theme) {
        backgroundView?.backgroundColor = theme.colors.chromeBackground
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.primaryText
        containerView.backgroundColor = theme.colors.midBackground
    }
}
