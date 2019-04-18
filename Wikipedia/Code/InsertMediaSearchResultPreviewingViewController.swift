import UIKit

class InsertMediaSearchResultPreviewingViewController: UIViewController {
    @IBOutlet private weak var imageView: AlignedImageView!
    @IBOutlet private weak var imageInfoViewContainer: UIView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private lazy var imageInfoView = InsertMediaImageInfoView.wmf_viewFromClassNib()!

    private let searchResult: InsertMediaSearchResult
    private let imageURL: URL
    private var theme = Theme.standard

    init(imageURL: URL, searchResult: InsertMediaSearchResult) {
        self.imageURL = imageURL
        self.searchResult = searchResult
        super.init(nibName: "InsertMediaSearchResultPreviewingViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { _ in }) {
            self.activityIndicator.stopAnimating()
        }
        imageInfoView.configure(with: searchResult, showLicenseName: false, theme: theme)
        imageInfoView.apply(theme: theme)
        imageInfoViewContainer.wmf_addSubviewWithConstraintsToEdges(imageInfoView)
        apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        preferredContentSize = view.systemLayoutSizeFitting(CGSize(width: view.bounds.size.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
    }
}

extension InsertMediaSearchResultPreviewingViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        activityIndicator.style = theme.isDark ? .white : .gray
    }
}
