import UIKit

class TalkPageViewController: ViewController {
    
    override init(theme: Theme) {
        super.init(theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "New talk page beta testing"
        view = UIView()
        view.backgroundColor = self.theme.colors.baseBackground
    }
    
}
