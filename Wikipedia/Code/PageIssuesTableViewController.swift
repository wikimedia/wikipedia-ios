import UIKit
import WMFComponents

class PageIssuesTableViewController: UITableViewController, WMFNavigationBarConfiguring {
    static let defaultViewCellReuseIdentifier = "org.wikimedia.default"

    fileprivate var theme = Theme.standard
    
    @objc var issues = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.estimatedRowHeight = 90.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: PageIssuesTableViewController.defaultViewCellReuseIdentifier)

        apply(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: WMFLocalizedString("page-issues", value: "Page issues", comment: "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates). {{Identical|Page issue}}"), customView: nil, alignment: .centerCompact)
        let closeButtonConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.doneTitle, target: self, action: #selector(closeButtonPressed), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func closeButtonPressed() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PageIssuesTableViewController.defaultViewCellReuseIdentifier, for: indexPath)

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        cell.textLabel?.text = issues[indexPath.row]
        
        cell.isUserInteractionEnabled = false
        cell.backgroundColor = self.theme.colors.paperBackground
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = self.theme.colors.midBackground
        cell.textLabel?.textColor = self.theme.colors.primaryText
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return issues.count
    }

}

extension PageIssuesTableViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        self.tableView.backgroundColor = theme.colors.baseBackground
        self.tableView.reloadData()
    }
}
