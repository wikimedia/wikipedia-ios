import UIKit

class InsertMediaImageViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    @IBOutlet private weak var centerYConstraint: NSLayoutConstraint?

    @IBOutlet private weak var overlayView: UIView!
    @IBOutlet private weak var infoView: UIView!
    @IBOutlet private weak var infoTitleLabel: UILabel!
    @IBOutlet private weak var infoLicenseImageView: UIImageView!
    @IBOutlet private weak var infoLicenseTitleLabel: UILabel!
    @IBOutlet private weak var infoMoreButton: UIButton!

    private var theme = Theme.standard
    private var display = Display.empty {
        didSet {
            switch display {
            case .empty:
                centerYConstraint?.isActive = true
                label.isHidden = false
            case .selected where oldValue == .empty:
                label.isHidden = true
                centerYConstraint?.isActive = false
                overlayView.isHidden = false
                infoView.isHidden = false
                fallthrough
            case .selected:
                imageView.backgroundColor = view.backgroundColor
            }
        }
    }

    private enum Display {
        case empty, selected
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = WMFLocalizedString("insert-media-placeholder-label-text", value: "Select or upload a file", comment: "Text for placeholder label visible when no file was selected or uploaded")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.font = UIFont.wmf_font(.semiboldHeadline, compatibleWithTraitCollection: traitCollection)
        infoTitleLabel.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        infoLicenseTitleLabel.font = UIFont.wmf_font(.semiboldCaption2, compatibleWithTraitCollection: traitCollection)
    }
}

extension InsertMediaImageViewController: InsertMediaSearchResultsCollectionViewControllerDelegate {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: MWKSearchResult, imageInfoResult: MWKImageInfo?) {
        guard let thumbnailURL = searchResult.thumbnailURL ?? imageInfoResult?.imageThumbURL else {
            assertionFailure()
            return
        }
        guard let imageURL = URL(string: WMFChangeImageSourceURLSizePrefix(thumbnailURL.absoluteString, Int(view.bounds.width))) else {
            return
        }

        imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { error in
            assertionFailure(error.localizedDescription)
        }) {
            self.display = .selected
            self.infoTitleLabel.text = imageInfoResult?.imageDescription
            self.infoLicenseTitleLabel.text = imageInfoResult?.license?.shortDescription
        }
    }
}

extension InsertMediaImageViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        label.textColor = theme.colors.overlayText
        view.backgroundColor = theme.colors.baseBackground
        imageView.backgroundColor = view.backgroundColor
        overlayView.backgroundColor = theme.colors.paperBackground
        infoTitleLabel.textColor = theme.colors.primaryText
        infoLicenseImageView.tintColor = theme.colors.primaryText
        infoLicenseTitleLabel.textColor = theme.colors.primaryText
        infoMoreButton.tintColor = theme.colors.link
    }
}
