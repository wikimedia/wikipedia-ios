import UIKit

class WMFExploreWrapperViewController: UIViewController, WMFExploreViewControllerDelegate {
    
    @IBOutlet weak var extendedNavBarView: UIView!
    
    public var userStore: MWKDataStore? {
        didSet {
            configureExploreViewController()
        }
    }
    
    private var exploreViewController: WMFExploreViewController? {
        didSet {
            configureExploreViewController()
        }
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "wikipedia"))
        self.navigationItem.leftBarButtonItem = settingsBarButtonItem()
        
        self.wmf_addBottomShadow(view: extendedNavBarView)
    }
    
    fileprivate func configureExploreViewController() {
        guard let vc = self.exploreViewController, let userStore = self.userStore else {
            //assertionFailure("Could not set user store") // TODO: not sure if we want this
            return
        }
        vc.userStore = userStore
        
        vc.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier,
            identifier == "embedCollectionViewController" else {
                return
        }
        guard let vc = segue.destination as? WMFExploreViewController else {
            assertionFailure("should be a WMFExploreViewController")
            return
        }
        
        exploreViewController = vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.wmf_updateNavigationBar(removeUnderline: true)
    }
    
    private func settingsBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action: #selector(didTapSettingsButton(_:)))
    }
    
    public func didTapSettingsButton(_ sender: UIBarButtonItem) {
        showSettings()
    }
    
    public func showSettings() {
        let settingsContainer = UINavigationController(rootViewController: WMFSettingsViewController.init(dataStore: self.userStore))
        present(settingsContainer, animated: true, completion: nil)
    }

    func exploreViewDidScroll(_ scrollView: UIScrollView) {
        
        DDLogDebug("scrolled!")
    }

}
