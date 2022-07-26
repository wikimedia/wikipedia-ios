import UIKit
import WMF

final class VanishAccountViewController: ViewController {
    
    @objc var dataStore: MWKDataStore!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(theme: Theme) {
        super.init(theme: theme)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIView()
        view.backgroundColor = self.theme.colors.baseBackground
        let label = UILabel(frame: CGRect(x: 0, y: 300, width: 200, height: 40))
        if let userName = dataStore.authenticationManager.loggedInUsername {
            label.text = userName
        }
        view.addSubview(label)
    }

}
