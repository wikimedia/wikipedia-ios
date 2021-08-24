import UIKit

final class InsertMediaSearchResultPreviewingViewController: UIViewController {
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
        imageView.accessibilityIgnoresInvertColors = true
        imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { _ in }) {
            self.imageView.backgroundColor = self.view.backgroundColor
            self.activityIndicator.stopAnimating()
        }
        imageInfoView.configure(with: searchResult, showLicenseName: false, showMoreInformationButton: false, theme: theme)
        imageInfoView.apply(theme: theme)
        imageInfoViewContainer.wmf_addSubviewWithConstraintsToEdges(imageInfoView)
        apply(theme: theme)
    }

    override var previewActionItems: [UIPreviewActionItem] {
        let selectImageAction = UIPreviewAction(title: WMFLocalizedString("insert-media-image-preview-select-image-action-title", value: "Select image", comment: "Title for preview action that results in image selection"), style: .default, handler: { [weak self] (_, _) in
            self?.selectImageAction?()
        })
        let moreInformationAction = UIPreviewAction(title: WMFLocalizedString("insert-media-image-preview-more-information-action-title", value: "More information", comment: "Title for preview action that results in presenting more information"), style: .default, handler: { [weak self] (_, _) in
            guard let url = self?.searchResult.imageInfo?.filePageURL else {
                return
            }
            self?.moreInformationAction?(url)
        })
        let cancelAction = UIPreviewAction(title: CommonStrings.cancelActionTitle, style: .default) { (_, _) in }
        return [selectImageAction, moreInformationAction, cancelAction]
    }
}

extension InsertMediaSearchResultPreviewingViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        imageView.backgroundColor = view.backgroundColor
        activityIndicator.color = theme.isDark ? .white : .gray
        imageInfoView.apply(theme: theme)
    }
}
