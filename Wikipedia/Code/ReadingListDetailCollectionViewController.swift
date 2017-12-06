import UIKit

class ReadingListDetailCollectionViewController: UIViewController {
    
    fileprivate var theme: Theme = Theme.standard
    
    @IBOutlet weak var containerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.title = "Back"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: nil)
        apply(theme: theme)
    }

}
extension ReadingListDetailCollectionViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
    }
    
    
}
