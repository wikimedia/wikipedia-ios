import UIKit

class InsertMediaImageInfoView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var licenseLabel: UILabel!
    @IBOutlet private weak var licenseStackView: UIStackView!
    @IBOutlet private weak var moreInformationButton: UIButton!

    var moreInformationAction: ((URL) -> Void)?

    private var moreInformationURL: URL? {
        didSet {
            moreInformationButton.isHidden = moreInformationURL == nil
        }
    }

    func configure(with searchResult: InsertMediaSearchResult, showImageDescription: Bool = true, theme: Theme) {
        titleLabel.text = searchResult.displayTitle
        moreInformationURL = searchResult.imageInfo?.filePageURL
        if showImageDescription, let imageDescription = searchResult.imageInfo?.imageDescription {
            descriptionLabel.numberOfLines = 5
            descriptionLabel.text = imageDescription
        } else {
            descriptionLabel.isHidden = true
        }
        for subview in licenseStackView.arrangedSubviews {
            licenseStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        if let codes = searchResult.imageInfo?.license?.code?.split(separator: "-") {
            licenseStackView.isHidden = false
            for code in codes {
                guard let image = UIImage(named: "license-\(code)") else {
                    continue
                }
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = theme.colors.primaryText
                licenseStackView.addArrangedSubview(imageView)
            }
        } else {
            licenseStackView.isHidden = true
        }
        licenseLabel.text = searchResult.imageInfo?.license?.shortDescription
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        licenseLabel.font = UIFont.wmf_font(.semiboldCaption2, compatibleWithTraitCollection: traitCollection)
    }

    @IBAction private func showMoreInformation(_ sender: UIButton) {
        guard let url = moreInformationURL else {
            return
        }
        moreInformationAction?(url)
    }
}

extension InsertMediaImageInfoView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.primaryText
        licenseLabel.textColor = theme.colors.primaryText
        moreInformationButton.tintColor = theme.colors.link
    }
}
