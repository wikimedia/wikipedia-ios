import WMFComponents

class PageHistoryCollectionViewCell: CollectionViewCell {
    private let roundedContent = UIView()
    private let editableContent = UIView()
    private let timeLabel = UILabel()
    private let sizeDiffLabel = UILabel()
    private let commentLabel = UILabel()
    private let authorButton = AlignedImageButton()
    private let selectView = BatchEditSelectView()
    private let spacing: CGFloat = 3
    private var theme = Theme.standard

    var time: String?

    var displayTime: String? {
        didSet {
            timeLabel.text = displayTime
            if let displayTime = displayTime {
                timeLabel.accessibilityLabel = String.localizedStringWithFormat(CommonStrings.revisionMadeFormat, displayTime)
            } else {
                timeLabel.accessibilityLabel = nil
            }
            setNeedsLayout()
        }
    }

    var sizeDiff: Int? {
        didSet {
            guard let sizeDiff = sizeDiff else {
                sizeDiffLabel.isHidden = true
                return
            }
            sizeDiffLabel.isHidden = false
            let added = sizeDiff > 0
            sizeDiffLabel.text = added ? "+\(sizeDiff)" : "\(sizeDiff)"
            if added || sizeDiff == 0 {
                sizeDiffLabel.accessibilityLabel = String.localizedStringWithFormat(WMFLocalizedString("page-history-revision-size-diff-addition", value: "Added {{PLURAL:%1$d|%1$d byte|%1$d bytes}}", comment: "Accessibility label text telling the user how many bytes were added in a revision - %1$@ is replaced with the number of bytes added in a revision"), sizeDiff)
            } else {
                sizeDiffLabel.accessibilityLabel = String.localizedStringWithFormat(WMFLocalizedString("page-history-revision-size-diff-subtraction", value: "Removed {{PLURAL:%1$d|%1$d byte|%1$d bytes}}", comment: "Accessibility label text telling the user how many bytes were removed in a revision - %1$d is replaced with the number of bytes removed in a revision"), abs(sizeDiff))
            }
            setNeedsLayout()
        }
    }

    var authorImage: UIImage? {
        didSet {
            setNeedsLayout()
        }
    }

    var author: String? {
        didSet {
            authorButton.setTitle(author, for: .normal)
            authorButton.accessibilityLabel = String.localizedStringWithFormat(CommonStrings.authorTitle, author ?? CommonStrings.unknownTitle)
            setNeedsLayout()
        }
    }

    func updateAccessibilityLabel() {
        let isMinorAccessibilityString = isMinor ? CommonStrings.minorEditTitle : ""
        accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [timeLabel.accessibilityLabel, authorButton.accessibilityLabel, sizeDiffLabel.accessibilityLabel, isMinorAccessibilityString, commentLabel.accessibilityLabel])
    }
    
    var comment: String? {
        didSet {
            if let comment = comment, comment.wmf_hasNonWhitespaceText {
                commentLabel.accessibilityLabel = String.localizedStringWithFormat(WMFLocalizedString("page-history-revision-comment-accessibility-label", value: "Comment %@", comment: "Accessibility label text of author's comment on the revision  - %@ is replaced with revision comment"), comment)
            } else {
                commentLabel.accessibilityLabel = nil
            }
            setNeedsLayout()
        }
    }

    var isMinor: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }

    private var isEditing = false {
        didSet {
            setNeedsLayout()
        }
    }

    private var isEditingEnabled = true {
        didSet {
            apply(theme: theme)
            setNeedsLayout()
        }
    }

    var selectionOrder: SelectionOrder?
    var selectionThemeModel: PageHistoryCollectionViewCellSelectionThemeModel?

    func setEditing(_ editing: Bool) {
        guard editing != isEditing else {
            return
        }
        selectView.isSelected = isSelected
        isEditing = editing
        selectView.alpha = editing ? 1 : 0
        layoutIfNeeded()
    }

    func enableEditing(_ enableEditing: Bool) {
        guard !isSelected else {
            return
        }
        layoutIfNeeded()
        selectView.layoutIfNeeded()
        isEditingEnabled = enableEditing
        selectView.isSelectionDisabled = !enableEditing
        layoutIfNeeded()
    }

    override func setup() {
        super.setup()
        roundedContent.layer.cornerRadius = 6
        roundedContent.layer.masksToBounds = true
        roundedContent.layer.borderWidth = 1

        editableContent.addSubview(timeLabel)
        editableContent.addSubview(sizeDiffLabel)
        authorButton.horizontalSpacing = 8
        authorButton.isUserInteractionEnabled = false
        authorButton.accessibilityTraits = UIAccessibilityTraits.staticText
        editableContent.addSubview(authorButton)
        commentLabel.numberOfLines = 2
        commentLabel.lineBreakMode = .byTruncatingTail
        editableContent.addSubview(commentLabel)
        selectView.alpha = 0
        selectView.clipsToBounds = true
        roundedContent.addSubview(selectView)
        roundedContent.addSubview(editableContent)
        contentView.addSubview(roundedContent)
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraits.link
    }

    override func reset() {
        super.reset()
        isEditing = false
        isEditingEnabled = true
        selectView.isSelectionDisabled = false
        selectionThemeModel = nil
        selectionOrder = nil
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        timeLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        sizeDiffLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        authorButton.titleLabel?.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        if let comment,
           !comment.isEmpty {
            commentLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        } else {
            commentLabel.font = WMFFont.for(.italicFootnote, compatibleWith: traitCollection)
        }
        
    }

    override var isSelected: Bool {
        didSet {
            selectView.isSelected = isSelected
        }
    }

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let layoutMargins = calculatedLayoutMargins

        let widthMinusMargins = layoutWidth(for: size)

        let innerMargins = UIEdgeInsets(top: layoutMargins.top, left: 15, bottom: layoutMargins.bottom, right: 15)

        roundedContent.frame = CGRect(x: layoutMargins.left, y: 0, width: widthMinusMargins, height: bounds.height)
        editableContent.frame = CGRect(x: 0, y: 0, width: widthMinusMargins, height: bounds.height)

        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let semanticContentAttribute: UISemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight

        if isEditing {
            let selectViewWidth: CGFloat = 30
            let spaceOccupiedBySelectView: CGFloat = selectViewWidth * 2 + spacing
            let x = isRTL ? widthMinusMargins - spaceOccupiedBySelectView + (selectViewWidth / 2) : (spaceOccupiedBySelectView / 2) - (selectViewWidth / 2)
            selectView.frame = CGRect(x: x, y: 0, width: selectViewWidth, height: bounds.height)
            selectView.alpha = 1
            selectView.layoutIfNeeded()
            let editableContentX = isRTL ? 0 : editableContent.frame.origin.x + spaceOccupiedBySelectView
            editableContent.frame = CGRect(x: editableContentX, y: 0, width: widthMinusMargins - spaceOccupiedBySelectView, height: bounds.height)
        } else {
            let x = isRTL ? roundedContent.frame.maxX : 0
            selectView.frame.origin = CGPoint(x: x, y: 0)
            selectView.alpha = 0
            editableContent.frame = CGRect(x: 0, y: 0, width: widthMinusMargins, height: bounds.height)
        }

        let availableWidth = editableContent.frame.width - innerMargins.right - innerMargins.left
        let leadingPaneAvailableWidth = availableWidth / 3

        let trailingPaneAvailableWidth: CGFloat
        if isRTL {
            trailingPaneAvailableWidth = availableWidth - leadingPaneAvailableWidth - innerMargins.left
        } else {
            trailingPaneAvailableWidth = availableWidth - leadingPaneAvailableWidth - spacing * 2
        }

        var leadingPaneOrigin = CGPoint(x: isRTL ? availableWidth - leadingPaneAvailableWidth : innerMargins.left, y: layoutMargins.top)
        var trailingPaneOrigin = CGPoint(x: isRTL ? innerMargins.left : innerMargins.left + leadingPaneAvailableWidth + spacing * 2, y: layoutMargins.top)

        if timeLabel.wmf_hasText {
            let timeLabelFrame = timeLabel.wmf_preferredFrame(at: leadingPaneOrigin, maximumWidth: leadingPaneAvailableWidth, alignedBy: semanticContentAttribute, apply: apply)
            leadingPaneOrigin.y += timeLabelFrame.layoutHeight(with: spacing * 2)
            timeLabel.isHidden = false
        } else {
            timeLabel.isHidden = true
        }

        if sizeDiffLabel.wmf_hasText {
            let sizeDiffLabelFrame = sizeDiffLabel.wmf_preferredFrame(at: leadingPaneOrigin, maximumWidth: leadingPaneAvailableWidth, alignedBy: semanticContentAttribute, apply: apply)
            leadingPaneOrigin.y += sizeDiffLabelFrame.layoutHeight(with: spacing)
            sizeDiffLabel.isHidden = false
        } else {
            sizeDiffLabel.isHidden = true
        }

        authorButton.semanticContentAttribute = semanticContentAttribute

        if authorButton.titleLabel?.wmf_hasText ?? false {
            if apply {
                authorButton.setImage(authorImage, for: .normal)
            }
            let authorButtonFrame = authorButton.wmf_preferredFrame(at: trailingPaneOrigin, maximumWidth: trailingPaneAvailableWidth, alignedBy: semanticContentAttribute, apply: apply)
            trailingPaneOrigin.y += authorButtonFrame.layoutHeight(with: spacing * 3)
            authorButton.isHidden = false
        } else {
            authorButton.isHidden = true
        }

        if let comment = comment {
            if isMinor, let minorImage = UIImage(named: "minor-edit") {
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = minorImage
                let attributedText = NSMutableAttributedString(attachment: imageAttachment)
                let attributedComment = comment.isEmpty ? CommonStrings.emptyEditSummary : comment
                attributedText.append(NSAttributedString(string: " \(attributedComment)"))
                commentLabel.attributedText = attributedText
            } else {
                commentLabel.text = comment.isEmpty ? CommonStrings.emptyEditSummary : comment
            }
            // TODO: Make sure all icons have the same sizes
            let commentLabelFrame = commentLabel.wmf_preferredFrame(at: trailingPaneOrigin, maximumWidth: trailingPaneAvailableWidth, alignedBy: semanticContentAttribute, apply: apply)
            trailingPaneOrigin.y += commentLabelFrame.layoutHeight(with: spacing)
            commentLabel.isHidden = false
        } else {
            commentLabel.text = CommonStrings.emptyEditSummary
        }
        let height = max(leadingPaneOrigin.y, trailingPaneOrigin.y) + layoutMargins.bottom
        selectView.frame.size = CGSize(width: selectView.frame.width, height: height)
        return CGSize(width: size.width, height: height)
    }
}

extension PageHistoryCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        if let selectionThemeModel = selectionThemeModel {
            selectView.selectedImage = selectionThemeModel.selectedImage
            roundedContent.layer.borderColor = selectionThemeModel.borderColor.cgColor
            roundedContent.backgroundColor = selectionThemeModel.backgroundColor
            authorButton.setTitleColor(selectionThemeModel.authorColor, for: .normal)
            authorButton.tintColor = selectionThemeModel.authorColor
            if comment?.isEmpty ?? true {
                commentLabel.textColor = selectionThemeModel.emptyCommentColor
            } else {
                commentLabel.textColor = selectionThemeModel.commentColor
            }
            
            timeLabel.textColor = selectionThemeModel.timeColor

            if let sizeDiff = sizeDiff {
                if sizeDiff == 0 {
                    sizeDiffLabel.textColor = selectionThemeModel.sizeDiffNoDifferenceColor
                } else if sizeDiff > 0 {
                    sizeDiffLabel.textColor = selectionThemeModel.sizeDiffAdditionColor
                } else {
                    sizeDiffLabel.textColor = selectionThemeModel.sizeDiffSubtractionColor
                }
            }
        } else {
            // themeTODO: define a semantic color for this instead of checking isDark
            roundedContent.layer.borderColor = theme.isDark ? WMFColor.gray300.cgColor : theme.colors.border.cgColor
            roundedContent.backgroundColor = theme.colors.paperBackground
            authorButton.setTitleColor(theme.colors.link, for: .normal)
            authorButton.tintColor = theme.colors.link
            if comment?.isEmpty ?? true {
                commentLabel.textColor = theme.colors.secondaryText
            } else {
                commentLabel.textColor = theme.colors.primaryText
            }
            
            timeLabel.textColor = theme.colors.secondaryText

            if let sizeDiff = sizeDiff {
                if sizeDiff == 0 {
                    sizeDiffLabel.textColor = theme.colors.link
                } else if sizeDiff > 0 {
                    sizeDiffLabel.textColor = theme.colors.accent
                } else {
                    sizeDiffLabel.textColor = theme.colors.destructive
                }
            }
        }
        selectView.apply(theme: theme)
    }
}
