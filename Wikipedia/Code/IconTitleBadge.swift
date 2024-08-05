import WMFComponents

class IconTitleBadge: SizeThatFitsView {
    
    enum Icon {
        case sfSymbol(name: String)
        case custom(name: String)
    }
    
    struct Configuration {
        let title: String
        let icon: Icon
    }
    
    private var iconImageView: UIImageView?
    private let titleLabel = UILabel()
    private let configuration: Configuration
    private var theme: Theme?
    
    init(configuration: Configuration, frame: CGRect) {
        self.configuration = configuration
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let padding = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
        let maximumWidth = size.width - padding.left - padding.right
        
        var x = padding.left
        var y = padding.top
        
        let imageTitleSpacing: CGFloat = 5
        
        var imageFrame: CGRect?
        if let imageView = iconImageView {
            let imageOrigin = CGPoint(x: x, y: y)
            imageFrame = imageView.wmf_preferredFrame(at: imageOrigin, maximumWidth: maximumWidth, alignedBy: semanticContentAttribute, apply: apply)
            x += (imageFrame?.width ?? 0) + imageTitleSpacing
        }
        
        let titleOrigin = CGPoint(x: x, y: y)
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumWidth: maximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        x += titleFrame.width + padding.right
        y += max(titleFrame.height, imageFrame?.height ?? 0)
        y += padding.bottom
        
        return CGSize(width: x, height: y)
    }
    
    override func setup() {
        super.setup()
        
        titleLabel.text = configuration.title
        addSubview(titleLabel)
        updateFonts(with: traitCollection)
        layer.cornerRadius = 3
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        
        let font = WMFFont.for(.boldSubheadline, compatibleWith: traitCollection)
        
        let icon: UIImage?
        switch configuration.icon {
        case .sfSymbol(let symbolName):
            let configuration = UIImage.SymbolConfiguration(font: font)
            icon = UIImage(systemName: symbolName, withConfiguration: configuration)
        case .custom(let iconName):
            icon = UIImage(named: iconName)
        }
        
        titleLabel.font = font
        if let icon = icon {
            iconImageView?.removeFromSuperview()
            let imageView = UIImageView(image: icon)
            addSubview(imageView)
            iconImageView = imageView
        }
        
    }
}

extension IconTitleBadge: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        iconImageView?.tintColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.secondaryText
        backgroundColor = theme.colors.baseBackground
    }
}
