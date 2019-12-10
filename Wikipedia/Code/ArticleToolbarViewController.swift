
import UIKit

class ArticleToolbarViewController: UIViewController {
    
    private let toolbarView = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        toolbarView.backgroundColor = .green
    }

}

private extension ArticleToolbarViewController {
    
    func setup() {
        
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbarView)
        view.wmf_addConstraintsToEdgesOfView(toolbarView)
    }
}
