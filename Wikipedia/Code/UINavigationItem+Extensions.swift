import Foundation
import UIKit

extension UINavigationItem {
    
    func configureForEmptyNavBarTitle(backTitle: String?) {
        // Allows detection when performing long press popping
        title = backTitle
        
        // Hides title display in navigation bar that previous line causes
        titleView = UIView()
        
        // Sets title in long press back contextual menu
        backButtonTitle = backTitle
        
        // Enables back button to display "Back" in navigation bar instead of full button title.
        backButtonDisplayMode = .generic
    }
}

extension UINavigationItem: @retroactive NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let newItem = UINavigationItem(title: title ?? "")
        newItem.titleView = titleView
        newItem.leftBarButtonItems = leftBarButtonItems
        newItem.rightBarButtonItems = rightBarButtonItems
        newItem.backBarButtonItem = backBarButtonItem
        newItem.backButtonTitle = backButtonTitle
        newItem.backButtonDisplayMode = backButtonDisplayMode
        return newItem
    }
}
