import UIKit
import WMF

final class VanishAccountViewController: ViewController {
    
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
    }

}
