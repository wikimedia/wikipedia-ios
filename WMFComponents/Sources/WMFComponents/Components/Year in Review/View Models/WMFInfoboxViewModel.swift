import Foundation

public class WMFInfoboxViewModel {
    let tableItems: [TableItem]

    public init(tableItems: [TableItem]) {
        self.tableItems = tableItems
    }
}

public struct TableItem {
    public let title: String
    public let text: String?
    public let attributedText: AttributedString?

    public init(title: String, text: String) {
        self.title = title
        self.text = text
        self.attributedText = nil
    }

    public init(title: String, attributedText: AttributedString) {
        self.title = title
        self.text = nil
        self.attributedText = attributedText
    }
}

