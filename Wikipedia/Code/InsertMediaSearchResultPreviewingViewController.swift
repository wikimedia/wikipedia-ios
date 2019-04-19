import UIKit

class InsertMediaSearchResultPreviewingViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageInfoViewContainer: UIView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private lazy var imageInfoView = InsertMediaImageInfoView.wmf_viewFromClassNib()!

    var selectImageAction: (() -> Void)?
    var moreInformationAction: ((URL) -> Void)?

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
        imageInfoView.moreInformationAction = moreInformationAction
        imageInfoView.apply(theme: theme)
        imageInfoViewContainer.wmf_addSubviewWithConstraintsToEdges(imageInfoView)
        apply(theme: theme)
    }

    override var previewActionItems: [UIPreviewActionItem] {
        let selectImageAction = UIPreviewAction(title: "Select image", style: .default, handler: { [weak self] (_, _) in
            self?.selectImageAction?()
        })
        let cancelAction = UIPreviewAction(title: CommonStrings.cancelActionTitle, style: .default) { (_, _) in }
        return [selectImageAction, cancelAction]
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
