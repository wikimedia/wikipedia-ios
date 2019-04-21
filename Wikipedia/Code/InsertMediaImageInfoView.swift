import UIKit

class InsertMediaImageInfoView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var licenseLabel: UILabel!
    @IBOutlet private weak var licenseStackView: UIStackView!
    @IBOutlet private weak var moreInformationButton: UIButton!

    var moreInformationAction: ((URL) -> Void)?
    private var keepBackgroundClear = false

    private var moreInformationURL: URL? {
        didSet {
            moreInformationButton.isHidden = moreInformationURL == nil
        }
    }

    func configure(with searchResult: InsertMediaSearchResult, showImageDescription: Bool = true, showLicenseName: Bool = true, showMoreInformationButton: Bool = true, keepBackgroundClear: Bool = false, theme: Theme) {
        titleLabel.text = searchResult.displayTitle
        moreInformationURL = searchResult.imageInfo?.filePageURL
        if showImageDescription, let imageDescription = searchResult.imageInfo?.imageDescription {
            descriptionLabel.numberOfLines = 5
            descriptionLabel.text = imageDescription
        } else {
            descriptionLabel.isHidden = true
        }

        moreInformationButton.isHidden = !showMoreInformationButton

        for subview in licenseStackView.arrangedSubviews {
            licenseStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        if let codes = searchResult.imageInfo?.license?.code?.split(separator: "-") {
            licenseStackView.isHidden = false
            for code in codes {
                guard let imageView = licenseImageView(withImageNamed: "license-\(code)", theme: theme) else {
                    continue
                }
                licenseStackView.addArrangedSubview(imageView)
            }
        }
        if licenseStackView.arrangedSubviews.isEmpty {
            if let imageView = licenseImageView(withImageNamed: "license-generic", theme: theme) {
                licenseStackView.addArrangedSubview(imageView)
            } else {
                licenseStackView.isHidden = true
            }
        }
        if showLicenseName {
            licenseLabel.text = searchResult.imageInfo?.license?.shortDescription
        } else {
            licenseLabel.isHidden = true
        }
        setNeedsLayout()
        self.keepBackgroundClear = keepBackgroundClear
        apply(theme: theme)
    }

    private func licenseImageView(withImageNamed imageName: String, theme: Theme) -> UIImageView? {
        guard let image = UIImage(named: imageName) else {
            return nil
        }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = theme.colors.primaryText
        return imageView
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
        backgroundColor = keepBackgroundClear ? .clear : theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.primaryText
        licenseLabel.textColor = theme.colors.primaryText
        moreInformationButton.tintColor = theme.colors.link
        moreInformationButton.backgroundColor = backgroundColor
    }
}
