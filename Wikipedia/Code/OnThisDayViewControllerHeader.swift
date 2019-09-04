import UIKit

class OnThisDayViewControllerHeader: UICollectionReusableView {
    @IBOutlet weak var eventsLabel: UILabel!
    @IBOutlet weak var onLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
        apply(theme: Theme.standard)
        wmf_configureSubviewsForDynamicType()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        onLabel.font = UIFont.wmf_font(.heavyTitle1, compatibleWithTraitCollection: traitCollection)
    }
    
    func configureFor(eventCount: Int, firstEvent: WMFFeedOnThisDayEvent?, lastEvent: WMFFeedOnThisDayEvent?, midnightUTCDate: Date) {
    
        let language = firstEvent?.language
        let locale = NSLocale.wmf_locale(for: language)
        
        semanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: language)
        eventsLabel.semanticContentAttribute = semanticContentAttribute
        onLabel.semanticContentAttribute = semanticContentAttribute
        fromLabel.semanticContentAttribute = semanticContentAttribute
        
        eventsLabel.text = String(format: WMFLocalizedString("on-this-day-detail-header-title", language: language, value:"{{PLURAL:%1$d|%1$d historical event|%1$d historical events}}", comment:"Title for 'On this day' detail view - %1$d is replaced with the number of historical events which occurred on the given day"), locale: locale, eventCount).uppercased(with: locale)
        
        onLabel.text = DateFormatter.wmf_monthNameDayNumberGMTFormatter(for: language).string(from: midnightUTCDate)
        
        if let firstEventEraString = firstEvent?.yearString, let lastEventEraString = lastEvent?.yearString {
            fromLabel.text = String(format: WMFLocalizedString("on-this-day-detail-header-date-range", language: language, value:"from %1$@ - %2$@", comment:"Text for 'On this day' detail view events 'year range' label - %1$@ is replaced with string version of the oldest event year - i.e. '300 BC', %2$@ is replaced with string version of the most recent event year - i.e. '2006', "), locale: locale, lastEventEraString, firstEventEraString)
        } else {
            fromLabel.text = nil
        }
    }
}

extension OnThisDayViewControllerHeader: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        eventsLabel.textColor = theme.colors.secondaryText
        onLabel.textColor = theme.colors.primaryText
        fromLabel.textColor = theme.colors.secondaryText
    }
}
