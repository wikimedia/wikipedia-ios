import UIKit
import SafariServices

final class InsertMediaExtendedViewController: UIViewController {
    @IBOutlet private weak var selectedImageContainerView: UIView!
    @IBOutlet private weak var searchContainerView: UIView!

    private let searchViewController: InsertMediaSearchViewController
    let selectedImageViewController = InsertMediaSelectedImageViewController()

    private var theme = Theme.standard

    var selectedImage: UIImage? {
        return selectedImageViewController.image
    }

    var selectedSearchResult: InsertMediaSearchResult? {
        return selectedImageViewController.searchResult
    }

    init(searchViewController: InsertMediaSearchViewController) {
        self.searchViewController = searchViewController
        super.init(nibName: "InsertMediaExtendedViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        wmf_add(childController: selectedImageViewController, andConstrainToEdgesOfContainerView: selectedImageContainerView)
        wmf_add(childController: searchViewController, andConstrainToEdgesOfContainerView: searchContainerView)
        apply(theme: theme)
    }
}

extension InsertMediaExtendedViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        selectedImageViewController.apply(theme: theme)
        searchViewController.apply(theme: theme)
    }
}
