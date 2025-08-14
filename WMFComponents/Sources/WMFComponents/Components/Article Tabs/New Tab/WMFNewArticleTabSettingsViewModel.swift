import Foundation
import Combine
import WMFData

public final class WMFNewArticleTabSettingsViewModel: ObservableObject {
    public let title: String
    public let header: String
    public let options: [String]
    public let saveSelection: (Int) -> Void

    @Published public var selectedIndex: Int {
        didSet {
            saveSelection(selectedIndex)
        }
    }
    
    public func shouldShowCheckmark(for index: Int) -> Bool {
        selectedIndex == index
    }

    public init(title: String, header: String, options: [String], saveSelection: @escaping (Int) -> Void, selectedIndex: Int) {
        self.title = title
        self.header = header
        self.options = options
        self.saveSelection = saveSelection
        self.selectedIndex = selectedIndex
    }
}
