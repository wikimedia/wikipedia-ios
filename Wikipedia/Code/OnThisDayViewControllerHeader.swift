import WMFComponents

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
        onLabel.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
    }
    
    func configureFor(eventCount: Int, firstEvent: WMFFeedOnThisDayEvent?, lastEvent: WMFFeedOnThisDayEvent?, midnightUTCDate: Date) {
    
        let languageCode = firstEvent?.languageCode
        let locale = NSLocale.wmf_locale(for: languageCode)
        
        semanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: firstEvent?.contentLanguageCode)
        eventsLabel.semanticContentAttribute = semanticContentAttribute
        onLabel.semanticContentAttribute = semanticContentAttribute
        fromLabel.semanticContentAttribute = semanticContentAttribute
        
        eventsLabel.text = CommonStrings.onThisDayAdditionalEventsMessage(with: languageCode, locale: locale, eventsCount: eventCount).uppercased(with: locale)
        
        onLabel.text = DateFormatter.wmf_monthNameDayNumberGMTFormatter(for: languageCode).string(from: midnightUTCDate)
        
        if let firstEventEraString = firstEvent?.yearString, let lastEventEraString = lastEvent?.yearString {
            fromLabel.text = CommonStrings.onThisDayHeaderDateRangeMessage(with: languageCode, locale: locale, lastEvent: lastEventEraString, firstEvent: firstEventEraString)
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
