import WMFComponents

final class InsertMediaImageInfoView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var licenseLabel: UILabel!
    @IBOutlet private weak var licenseView: LicenseView!
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

        licenseView.licenseCodes = searchResult.imageInfo?.license?.code?.split(separator: "-").compactMap { String($0) } ?? []
        licenseView.isHidden = licenseView.licenseCodes.isEmpty
        if showLicenseName {
            licenseLabel.text = searchResult.imageInfo?.license?.shortDescription
        } else {
            licenseLabel.isHidden = true
        }
        updateFonts()
        setNeedsLayout()
        self.keepBackgroundClear = keepBackgroundClear
        apply(theme: theme)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        titleLabel.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        descriptionLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        licenseLabel.font = WMFFont.for(.boldCaption1, compatibleWith: traitCollection)
    }

    @IBAction private func showMoreInformation(_ sender: Any) {
        guard let url = moreInformationURL else {
            assertionFailure("moreInformationURL should be set by now")
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
        licenseView.tintColor = theme.colors.primaryText
    }
}
