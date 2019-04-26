import SafariServices

protocol InsertMediaSelectedImageViewControllerDelegate: AnyObject {
    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, didSetSelectedImage selectedImage: UIImage?, from searchResult: InsertMediaSearchResult)
}

final class InsertMediaSelectedImageViewController: UIViewController {
    private let selectedView = InsertMediaSelectedImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private var theme = Theme.standard
    weak var delegate: InsertMediaSelectedImageViewControllerDelegate?
    
    var image: UIImage? {
        return selectedView.image
    }

    var searchResult: InsertMediaSearchResult? {
        return selectedView.searchResult
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        wmf_showEmptyView(of: .noSelectedImageToInsert, theme: theme, frame: view.bounds)
        apply(theme: theme)
    }

    @objc private func startActivityIndicator() {
        cancelPreviousActivityIndicatorSelectors()
        view.isHidden = true
        activityIndicator.startAnimating()
    }

    @objc private func stopActivityIndicator() {
        cancelPreviousActivityIndicatorSelectors()
        view.isHidden = false
        activityIndicator.stopAnimating()
    }

    @objc private func cancelPreviousActivityIndicatorSelectors() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startActivityIndicator), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(stopActivityIndicator), object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityIndicator.center = view.center
    }
}

extension InsertMediaSelectedImageViewController: InsertMediaSearchResultsCollectionViewControllerDelegate {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: InsertMediaSearchResult) {
        perform(#selector(startActivityIndicator), with: nil, afterDelay: 0.3)
        guard let imageURL = searchResult.imageURL(for: view.bounds.width) else {
            stopActivityIndicator()
            return
        }
        selectedView.configure(with: imageURL, searchResult: searchResult, theme: theme) { error in
            guard error == nil else {
                self.stopActivityIndicator()
                return
            }
            self.stopActivityIndicator()
            if self.selectedView.superview == nil {
                self.wmf_hideEmptyView()
                self.selectedView.moreInformationAction = { [weak self] url in
                    self?.present(SFSafariViewController(url: url), animated: true)
                }
                self.view.wmf_addSubviewWithConstraintsToEdges(self.selectedView)
            }
            self.delegate?.insertMediaSelectedImageViewController(self, didSetSelectedImage: self.image, from: searchResult)
        }
    }
}

extension InsertMediaSelectedImageViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        activityIndicator.style = theme.isDark ? .white : .gray
    }
}
