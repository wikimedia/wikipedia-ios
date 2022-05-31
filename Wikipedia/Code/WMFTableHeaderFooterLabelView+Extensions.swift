import Foundation

@objc extension WMFTableHeaderFooterLabelView {
    @objc static func headerFooterViewForTableView(_ tableView: UITableView, text: String?, type: WMFTableHeaderFooterLabelViewType = .header, setShortTextAsProse: Bool = false, theme: Theme) -> WMFTableHeaderFooterLabelView? {
        
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
            
            return view
    }
}
