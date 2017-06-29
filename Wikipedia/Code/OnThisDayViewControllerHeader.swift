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
        
        eventsLabel.text = String.localizedStringWithFormat(WMFLocalizedString("on-this-day-detail-header-title", value:"%1$@ historical events", comment:"Title for 'On this day' detail view - %1$@ is replaced with the number of historical events which occured on the given day"), "\(eventCount)").uppercased(with: Locale.current)
        
        let onDayString = OnThisDayViewControllerHeader.monthNameDayNumberFormatter.string(from: date)
        
        onLabel.text = String.localizedStringWithFormat(WMFLocalizedString("on-this-day-detail-header-day", value:"on %1$@", comment:"Text for 'On this day' detail view 'day' label - %1$@ is replaced with string version of the given day - i.e. 'January 23'"), onDayString)
        
        if let firstEventEraString = firstEvent?.yearWithEraString(), let lastEventEraString = lastEvent?.yearWithEraString() {
            fromLabel.text = String.localizedStringWithFormat(WMFLocalizedString("on-this-day-detail-header-date-range", value:"from %1$@ - %2$@", comment:"Text for 'On this day' detail view events 'year range' label - %1$@ is replaced with string version of the most recent event year - i.e. '2006 AD', %2$@ is replaced with string version of the oldest event year - i.e. '300 BC', "), firstEventEraString, lastEventEraString)
        } else {
            fromLabel.text = nil
        }
    }
    
    private static let monthNameDayNumberFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.autoupdatingCurrent
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM d")
        return dateFormatter
    }()
}
