import Foundation

// Utilize this class to define localized strings that are used in multiple places in similar contexts.
// There should only be one WMFLocalizedString() function in code for every localization key.
// If the same string value is used in different contexts, use different localization keys.

@objc(WMFCommonStrings)
public class CommonStrings: NSObject {
    public static let shortSavedTitle = WMFLocalizedString("action-saved", value:"Saved", comment:"Short title for the save button in the 'Saved' state - Indicates the article is saved. Please use the shortest translation possible.\n{{Identical|Saved}}")
    public static let accessibilitySavedTitle = WMFLocalizedString("action-saved-accessibility", value:"Saved. Activate to unsave.", comment:"Accessibility title for the 'Unsave' action\n{{Identical|Saved}}")
    public static let shortUnsaveTitle = WMFLocalizedString("action-unsave", value:"Unsave", comment:"Short title for the 'Unsave' action. Please use the shortest translation possible.\n{{Identical|Saved}}")
    
    public static let shortSaveTitle = WMFLocalizedString("action-save", value:"Save", comment:"Title for the 'Save' action\n{{Identical|Save}}")
    public static let savedTitle:String = CommonStrings.savedTitle(language: nil)
    public static let saveTitle:String = CommonStrings.saveTitle(language: nil)
    
    static public func savedTitle(language: String?) -> String {
        return WMFLocalizedString("button-saved-for-later", language: language, value:"Saved for later", comment:"Longer button text for already saved button used in various places.")
    }
    
    static public func saveTitle(language: String?) -> String {
        return WMFLocalizedString("button-save-for-later", language: language, value:"Save for later", comment:"Longer button text for save button used in various places.")
    }
    
    public static let shortShareTitle = WMFLocalizedString("action-share", value:"Share", comment:"Short title for the 'Share' action. Please use the shortest translation possible.\n{{Identical|Share}}")
    
    public static let shortReadTitle = WMFLocalizedString("action-read", value:"Read", comment:"Title for the 'Read' action\n{{Identical|Read}}")
}
