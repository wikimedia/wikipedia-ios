import UIKit

public class NewsCollectionViewCell: SideScrollingCollectionViewCell {

    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        updateDescriptionHTMLStyle()
    }
    
    override public func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        collectionView.backgroundColor = labelBackgroundColor
    }
    
    func updateDescriptionHTMLStyle() {
        guard let descriptionHTML = descriptionHTML else {
            descriptionLabel.text = nil
            return
        }
        let attributedString = descriptionHTML.byAttributingHTML(with: .subheadline, boldWeight: .semibold, matching: traitCollection, color: descriptionLabel.textColor, tagMapping: ["a":"b"])
        descriptionLabel.attributedText = attributedString
    }
    
    var descriptionHTML: String? {
        didSet {
            updateDescriptionHTMLStyle()
        }
    }
}

public class NewsExploreCollectionViewCell: NewsCollectionViewCell {
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
    }
}
