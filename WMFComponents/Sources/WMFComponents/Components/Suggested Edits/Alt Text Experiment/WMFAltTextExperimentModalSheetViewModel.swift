import Foundation

@objc final public class WMFAltTextExperimentModalSheetViewModel: NSObject {
    public var altTextViewModel: WMFAltTextExperimentViewModel
    public var localizedStrings: LocalizedStrings

    public struct LocalizedStrings {
        public var title: String
        public var buttonTitle: String
        public var textViewPlaceholder: String

        public init(title: String, buttonTitle: String, textViewPlaceholder: String) {
            self.title = title
            self.buttonTitle = buttonTitle
            self.textViewPlaceholder = textViewPlaceholder
        }
    }

    public init(altTextViewModel: WMFAltTextExperimentViewModel, localizedStrings: LocalizedStrings) {
        self.altTextViewModel = altTextViewModel
        self.localizedStrings = localizedStrings
    }

}
