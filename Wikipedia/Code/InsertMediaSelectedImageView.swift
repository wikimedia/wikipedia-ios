import UIKit

class InsertMediaSelectedImageView: UIView {
    @IBOutlet private weak var imageView: UIImageView!

    @IBOutlet private weak var overlayView: UIView!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var licensesStackView: UIStackView!
    @IBOutlet private weak var licenseLabel: UILabel!
    @IBOutlet private weak var moreInformationButton: UIButton!

    public var moreInformationAction: ((URL) -> Void)?

    private var moreInformationURL: URL? {
        didSet {
            moreInformationButton.isHidden = moreInformationURL == nil
        }
    }

    var image: UIImage? {
        return imageView.image
    }

    var searchResult: InsertMediaSearchResult?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        licenseLabel.font = UIFont.wmf_font(.semiboldCaption2, compatibleWithTraitCollection: traitCollection)
    }

    public func configure(with imageURL: URL, searchResult: InsertMediaSearchResult, theme: Theme, completion: @escaping (Error?) -> Void) {
        imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { error in
            completion(error)
        }) {
            self.searchResult = searchResult
            self.imageView.backgroundColor = self.backgroundColor
            self.configureInfoView(with: searchResult, theme: theme)
            completion(nil)
        }
    }

    private func configureInfoView(with searchResult: InsertMediaSearchResult, theme: Theme) {
        titleLabel.text = searchResult.displayTitle
        moreInformationURL = searchResult.imageInfo?.filePageURL
        reset(licensesStackView)

        if let codes = searchResult.imageInfo?.license?.code?.split(separator: "-") {
            licensesStackView.isHidden = false
            for code in codes {
                guard let image = UIImage(named: "license-\(code)") else {
                    continue
                }
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = theme.colors.primaryText
                licensesStackView.addArrangedSubview(imageView)
            }
        } else {
            licensesStackView.isHidden = true
        }
        licenseLabel.text = searchResult.imageInfo?.license?.shortDescription
    }

    private func reset(_ stackView: UIStackView) {
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }

    @IBAction private func showMoreInformation(_ sender: UIButton) {
        guard let url = moreInformationURL else {
            return
        }
        moreInformationAction?(url)
    }
}

extension InsertMediaSelectedImageView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.baseBackground
        imageView.backgroundColor = backgroundColor
        overlayView.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        licenseLabel.textColor = theme.colors.primaryText
        moreInformationButton.tintColor = theme.colors.link
    }
}
