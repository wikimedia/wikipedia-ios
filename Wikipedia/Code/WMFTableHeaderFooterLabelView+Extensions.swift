
import Foundation

@objc extension WMFTableHeaderFooterLabelView {
    @objc static func headerFooterViewForTableView(_ tableView: UITableView, text: String?, type: WMFTableHeaderFooterLabelViewType = .header, setShortTextAsProse: Bool = false, theme: Theme) -> WMFTableHeaderFooterLabelView? {
        
        //We don't want footer to add extra spacing at the bottom, so not returning a view at all here. Empty footer spacing plus empty header spacing looks too large.
        if type == .footer && text == nil {
            return nil
        }
        
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: WMFTableHeaderFooterLabelView.identifier) as? WMFTableHeaderFooterLabelView else {
                return nil
            }
        
            view.type = type
        
            if setShortTextAsProse {
                view.setShortTextAsProse(text)
            } else {
                view.text = text
            }
        
            if let view = view as Themeable? {
                view.apply(theme: theme)
            }
            
            return view;
    }
}
