protocol InsertMediaSelectedImageViewControllerDelegate: AnyObject {
    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, didSetSelectedImage selectedImage: UIImage?, from searchResult: InsertMediaSearchResult)
    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, willSetSelectedImageFrom searchResult: InsertMediaSearchResult)
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
        apply(theme: theme)
        view.addCenteredSubview(activityIndicator)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            wmf_showEmptyView(of: .noSelectedImageToInsert, theme: theme, frame: view.bounds)
        } else {
            wmf_hideEmptyView()
        }
    }

    private func startActivityIndicator() {
        wmf_hideEmptyView()
        cancelPreviousActivityIndicatorSelectors()
        selectedView.isHidden = true
        perform(#selector(_startActivityIndicator), with: nil, afterDelay: 0.3)
    }
    
    @objc private func _startActivityIndicator() {
        activityIndicator.startAnimating()
    }

    @objc private func stopActivityIndicator() {
        cancelPreviousActivityIndicatorSelectors()
        selectedView.isHidden = false
        activityIndicator.stopAnimating()
    }

    @objc private func cancelPreviousActivityIndicatorSelectors() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_startActivityIndicator), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(stopActivityIndicator), object: nil)
    }
}

extension InsertMediaSelectedImageViewController: InsertMediaSearchResultsCollectionViewControllerDelegate {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: InsertMediaSearchResult) {
        delegate?.insertMediaSelectedImageViewController(self, willSetSelectedImageFrom: searchResult)
        startActivityIndicator()
        guard let imageURL = searchResult.imageURL(for: view.bounds.width) else {
            stopActivityIndicator()
            return
        }
        if selectedView.moreInformationAction == nil {
            selectedView.moreInformationAction = { [weak self] url in
                self?.navigate(to: url, useSafari: true)
            }
        }
        selectedView.configure(with: imageURL, searchResult: searchResult, theme: theme) { error in
            guard error == nil else {
                self.stopActivityIndicator()
                return
            }
            self.stopActivityIndicator()
            if self.selectedView.superview == nil {
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
        wmf_applyTheme(toEmptyView: theme)
        view.backgroundColor = theme.colors.baseBackground
        activityIndicator.style = theme.isDark ? .white : .gray
    }
}
