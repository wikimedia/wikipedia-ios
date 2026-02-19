import WMF
import WMFComponents

/// Button with capsule style and multiline text support
@available(*, deprecated, message: "Kept and updated for temporary compatibility, use buttons from WMFComponenets instead")
class WMFAuthButton: AutoLayoutSafeMultiLineButton, Themeable {
    fileprivate var theme: Theme = Theme.standard

    override open func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override open func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)

        if state == .normal, var config = configuration, let title {
            config.title = title

            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = WMFFont.for(.boldCallout)
                return outgoing
            }
            configuration = config
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        configureTitleLabel()
    }

    // MARK: - Private Methods

    private func configureTitleLabel() {
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
    }

    override internal func setup() {
        super.setup()

        configureTitleLabel()

        var config = configuration ?? UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.background.backgroundColor = theme.colors.baseBackground
        config.baseForegroundColor = theme.colors.link
        config.titleLineBreakMode = .byWordWrapping
        config.titleAlignment = .center

        configuration = config

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        setup()
    }
}
