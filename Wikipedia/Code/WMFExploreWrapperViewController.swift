import UIKit

class WMFExploreWrapperViewController: UIViewController {
    
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
        
        self.wmf_addBottomShadow(view: extendedNavBarView)
    }
    
    fileprivate func configureExploreViewController() {
        guard let vc = self.exploreViewController, let userStore = self.userStore else {
            return
        }
        vc.userStore = userStore
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
}
