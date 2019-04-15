import UIKit
import SafariServices

protocol InsertMediaImageViewControllerDelegate: AnyObject {
    func insertMediaImageViewController(_ insertMediaImageViewController: InsertMediaImageViewController, didSetSelectedImage image: UIImage?, from searchResult: InsertMediaSearchResult)
}

final class InsertMediaImageViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    @IBOutlet private weak var centerYConstraint: NSLayoutConstraint?

    @IBOutlet private weak var overlayView: UIView!
    @IBOutlet private weak var infoView: UIView!
    @IBOutlet private weak var infoTitleLabel: UILabel!
    @IBOutlet private weak var infoLicensesStackView: UIStackView!
    @IBOutlet private weak var infoLicenseTitleLabel: UILabel!
    @IBOutlet private weak var infoMoreButton: UIButton!

    weak var delegate: InsertMediaImageViewControllerDelegate?

    private var moreInfoURL: URL? {
        didSet {
            infoMoreButton.isHidden = moreInfoURL == nil
        }
    }

    private var theme = Theme.standard

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

    @IBAction private func showMoreInfo(_ sender: UIButton) {
        guard let url = moreInfoURL else {
            assertionFailure()
            return
        }
        present(SFSafariViewController(url: url), animated: true)
    }
}

extension InsertMediaImageViewController: InsertMediaSearchResultsCollectionViewControllerDelegate {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: InsertMediaSearchResult) {
        guard let imageURL = URL(string: WMFChangeImageSourceURLSizePrefix(searchResult.thumbnailURL.absoluteString, Int(view.bounds.width))) else {
            return
        }

        imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { error in
            assertionFailure(error.localizedDescription)
        }) {
            self.imageView.contentMode = .scaleAspectFill
            self.moreInfoURL = searchResult.imageInfo?.filePageURL
            self.label.isHidden = true
            self.centerYConstraint?.isActive = false
            self.overlayView.isHidden = false
            self.infoView.isHidden = false
            self.imageView.backgroundColor = self.view.backgroundColor
            self.infoTitleLabel.text = searchResult.imageInfo?.imageDescription
            self.resetLicenseView()
            if let license = searchResult.imageInfo?.license {
                self.configureLicenseView(with: license)
            }
            self.delegate?.insertMediaImageViewController(self, didSetSelectedImage: self.imageView.image, from: searchResult)
        }
    }

    private func configureLicenseView(with license: MWKLicense) {
        if let codes = license.code?.split(separator: "-") {
            for code in codes {
                guard let image = UIImage(named: "license-\(code)") else {
                    continue
                }
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = theme.colors.primaryText
                infoLicensesStackView.addArrangedSubview(imageView)
            }
        }
        infoLicenseTitleLabel.text = license.shortDescription
    }

    private func resetLicenseView() {
        for subview in infoLicensesStackView.arrangedSubviews {
            infoLicensesStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
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
        infoLicenseTitleLabel.textColor = theme.colors.primaryText
        infoMoreButton.tintColor = theme.colors.link
    }
}
