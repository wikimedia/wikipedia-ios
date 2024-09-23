import WMFComponents

protocol DiffHeaderTitleViewTapDelegate: AnyObject {
    func userDidTapTitleLabel()
}

class DiffHeaderTitleView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!

    weak var titleViewTapDelegate: DiffHeaderTitleViewTapDelegate?

    private(set) var viewModel: DiffHeaderTitleViewModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    fileprivate func configureAccessibilityLabel(hasSubtitle: Bool) {
        if hasSubtitle {
            contentView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [headingLabel.text, titleLabel.text, subtitleLabel.text])
        } else {
            contentView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [headingLabel.text, titleLabel.text])
        }
    }

    func update(_ viewModel: DiffHeaderTitleViewModel, titleViewTapDelegate: DiffHeaderTitleViewTapDelegate? = nil) {

        self.viewModel = viewModel
        self.titleViewTapDelegate = titleViewTapDelegate

        headingLabel.text = viewModel.heading
        titleLabel.text = viewModel.title

        if let subtitle = viewModel.subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
            configureAccessibilityLabel(hasSubtitle: true)
        } else {
            subtitleLabel.isHidden = true
            configureAccessibilityLabel(hasSubtitle: false)
        }
        updateFonts(with: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }

        let titleConverted = convert(point, to: titleLabel)
        if titleLabel.point(inside: titleConverted, with: event) {
            return true
        }

        return false
    }
}

private extension DiffHeaderTitleView {
    func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderTitleView.wmf_nibName(), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        updateFonts(with: traitCollection)
        contentView.isAccessibilityElement = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userDidTapTitleLabel))
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(tapGesture)
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headingLabel.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        titleLabel.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
        if let viewModel = viewModel {
            subtitleLabel.font = WMFFont.for(viewModel.subtitleTextStyle, compatibleWith: traitCollection)
        } else {
            subtitleLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        }
    }

    @objc func userDidTapTitleLabel() {
        titleViewTapDelegate?.userDidTapTitleLabel()
    }
}

extension DiffHeaderTitleView: Themeable {
    func apply(theme: Theme) {
        
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.link

        if let subtitleColor = viewModel?.subtitleColor {
            subtitleLabel.textColor = subtitleColor
        } else {
            subtitleLabel.textColor = theme.colors.secondaryText
        }
    }
}
