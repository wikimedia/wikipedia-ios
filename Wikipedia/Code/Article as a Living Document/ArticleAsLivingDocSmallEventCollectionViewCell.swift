import WMFComponents

class ArticleAsLivingDocSmallEventCollectionViewCell: CollectionViewCell {
    private let descriptionLabel = UILabel()
    let timelineView = TimelineView()

    private var theme: Theme?
    
    private var smallEvent: ArticleAsLivingDocViewModel.Event.Small?

    weak var delegate: ArticleDetailsShowing?
    
    override func reset() {
        super.reset()
        descriptionLabel.text = nil
    }
    
    override func setup() {
        super.setup()
        contentView.addSubview(descriptionLabel)
        timelineView.decoration = .squiggle
        contentView.addSubview(timelineView)
        
        descriptionLabel.numberOfLines = 1
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedSmallChanges))
        descriptionLabel.addGestureRecognizer(tapGestureRecognizer)
        descriptionLabel.isUserInteractionEnabled = true
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        if traitCollection.horizontalSizeClass == .compact {
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: -5, bottom: 20, right: 0)
        } else {
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        }
        
        let layoutMargins = calculatedLayoutMargins
        
        let timelineTextSpacing: CGFloat = 5
        let timelineWidth: CGFloat = 15
        let x = layoutMargins.left + timelineWidth + timelineTextSpacing
        let widthToFit = size.width - layoutMargins.right - x
        
        if apply {
            timelineView.frame = CGRect(x: layoutMargins.left, y: 0, width: timelineWidth, height: size.height)
        }
        
        let descriptionOrigin = CGPoint(x: x + 3, y: layoutMargins.top)
        
        let descriptionFrame = descriptionLabel.wmf_preferredFrame(at: descriptionOrigin, maximumSize: CGSize(width: widthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = descriptionFrame.maxY + layoutMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(viewModel: ArticleAsLivingDocViewModel.Event.Small, theme: Theme) {
        
        self.smallEvent = viewModel
        descriptionLabel.text = viewModel.eventDescription
        apply(theme: theme)
        setNeedsLayout()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotsY = descriptionLabel.convert(descriptionLabel.bounds, to: timelineView).midY
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        
        descriptionLabel.font = WMFFont.for(.italicSubheadline, compatibleWith: traitCollection)
    }
    
    @objc private func tappedSmallChanges() {
        guard let revisionID = smallEvent?.smallChanges.first?.revId,
              let parentId = smallEvent?.smallChanges.last?.parentId else {
            return
        }
        
        let diffType: DiffContainerViewModel.DiffType = (smallEvent?.smallChanges.count ?? 0) > 1 ? .compare : .single
        
        delegate?.goToDiff(revisionId: revisionID, parentId: parentId, diffType: diffType)
    }
}

extension ArticleAsLivingDocSmallEventCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        
        if let oldTheme = self.theme,
           theme.webName == oldTheme.webName {
            return
        }
        
        self.theme = theme

        descriptionLabel.textColor = theme.colors.link
        timelineView.backgroundColor = theme.colors.paperBackground
        timelineView.tintColor = theme.colors.accent
    }
}
