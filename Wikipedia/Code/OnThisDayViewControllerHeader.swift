import UIKit

class OnThisDayViewControllerHeader: UICollectionReusableView {
    @IBOutlet weak var eventsLabel: UILabel!
    @IBOutlet weak var onLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .wmf_lightGrayCellBackground
        eventsLabel.textColor = .black
        onLabel.textColor = .wmf_blue
        fromLabel.textColor = .wmf_customGray
        wmf_configureSubviewsForDynamicType()
    }
    
    func configureFor(eventCount: Int, firstEvent: WMFFeedOnThisDayEvent?, lastEvent: WMFFeedOnThisDayEvent?, date: Date) {
        
        let siteURL = firstEvent?.siteURL
        let language = firstEvent?.language
        let locale = NSLocale.wmf_locale(for: language)
        
        semanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: language)
        eventsLabel.semanticContentAttribute = semanticContentAttribute
        onLabel.semanticContentAttribute = semanticContentAttribute
        fromLabel.semanticContentAttribute = semanticContentAttribute
        
        eventsLabel.text = String.localizedStringWithFormat(WMFLocalizedString("on-this-day-detail-header-title", siteURL: siteURL, value:"{{PLURAL:%1$d|%1$d historical event|%1$d historical events}}", comment:"Title for 'On this day' detail view - %1$d is replaced with the number of historical events which occured on the given day"), eventCount).uppercased(with: locale)
        
        let onDayString = DateFormatter.wmf_monthNameDayNumberGMTFormatter(for: language).string(from: date)
        
        onLabel.text = String.localizedStringWithFormat(WMFLocalizedString("on-this-day-detail-header-day", siteURL: siteURL, value:"on %1$@", comment:"Text for 'On this day' detail view 'day' label - %1$@ is replaced with string version of the given day - i.e. 'January 23'"), onDayString)
        
        if let firstEventEraString = firstEvent?.yearWithEraString, let lastEventEraString = lastEvent?.yearWithEraString {
            fromLabel.text = String.localizedStringWithFormat(WMFLocalizedString("on-this-day-detail-header-date-range", siteURL: siteURL, value:"from %1$@ - %2$@", comment:"Text for 'On this day' detail view events 'year range' label - %1$@ is replaced with string version of the most recent event year - i.e. '2006 AD', %2$@ is replaced with string version of the oldest event year - i.e. '300 BC', "), firstEventEraString, lastEventEraString)
        } else {
            fromLabel.text = nil
        }
    }
    

}
