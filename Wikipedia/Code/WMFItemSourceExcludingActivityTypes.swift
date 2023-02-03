import Foundation
import LinkPresentation

/// A UIActivityItemSource that hides an item from a list of activity types.
public class WMFItemSourceExcludingActivityTypes: NSObject, UIActivityItemSource {
    
    private let item: Any
    
    private let excludedActivityTypes: [UIActivity.ActivityType?]
    
    public init(item: Any, excludedActivityTypes: [UIActivity.ActivityType?]) {
        self.item = item
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return item
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if excludedActivityTypes.contains(activityType) {
            return nil
        }
        
        return item
    }
}

/// A UIActivityItemSource wrapper that hides a UIActivityItemSource from a list of activity types.
public class WMFItemSourceWrapperExcludingActivityTypes: NSObject, UIActivityItemSource {
    
    private let itemSource: UIActivityItemSource
    
    private let excludedActivityTypes: [UIActivity.ActivityType?]
    
    public init(itemSource: UIActivityItemSource, excludedActivityTypes: [UIActivity.ActivityType?]) {
        self.itemSource = itemSource
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return itemSource.activityViewControllerPlaceholderItem(activityViewController)
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if excludedActivityTypes.contains(activityType) {
            return nil
        }
        
        return itemSource.activityViewController(activityViewController, itemForActivityType: activityType)
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        if excludedActivityTypes.contains(activityType) {
            return ""
        }
        
        return itemSource.activityViewController?(activityViewController, subjectForActivityType: activityType) ?? ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        if excludedActivityTypes.contains(activityType) {
            return ""
        }
        
        return itemSource.activityViewController?(activityViewController, dataTypeIdentifierForActivityType: activityType) ?? ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        if excludedActivityTypes.contains(activityType) {
            return nil
        }
        
        return itemSource.activityViewController?(activityViewController, thumbnailImageForActivityType: activityType, suggestedSize: size)
    }
    
    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return itemSource.activityViewControllerLinkMetadata?(activityViewController)
    }
}
