import Foundation
import Combine
import WMFData

public protocol WMFNewArticleTabSettingsLoggingDelegate: AnyObject {
    func logPreference(index:Int)
}

public final class WMFNewArticleTabSettingsViewModel: ObservableObject {
    public let title: String
    public let header: String
    public let options: [String]
    public let saveSelection: (Int) -> Void
    weak var loggingDelegate: WMFNewArticleTabSettingsLoggingDelegate?

    @Published public var selectedIndex: Int {
        didSet {
            saveSelection(selectedIndex)
            loggingDelegate?.logPreference(index: selectedIndex)
        }
    }
    
    public func shouldShowCheckmark(for index: Int) -> Bool {
        selectedIndex == index
    }

    public init(title: String, header: String, options: [String], saveSelection: @escaping (Int) -> Void, selectedIndex: Int, loggingDelegate: WMFNewArticleTabSettingsLoggingDelegate?) {
        self.title = title
        self.header = header
        self.options = options
        self.saveSelection = saveSelection
        self.selectedIndex = selectedIndex
        self.loggingDelegate = loggingDelegate
    }
}
