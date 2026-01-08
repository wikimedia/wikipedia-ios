import Foundation

public class WMFInfoboxViewModel {
    let logoCaption: String
    let tableItems: [TableItem]

    public init(logoCaption: String, tableItems: [TableItem]) {
        self.logoCaption = logoCaption
        self.tableItems = tableItems
    }
}

public struct TableItem {
    public let title: String

    public let text: String?
    public let richRows: [InfoboxRichRow]?

    public init(title: String, text: String) {
        self.title = title
        self.text = text
        self.richRows = nil
    }

    public init(title: String, richRows: [InfoboxRichRow]) {
        self.title = title
        self.text = nil
        self.richRows = richRows
    }
}

public struct InfoboxRichRow: Identifiable {
    public let id = UUID()
    public let numberText: AttributedString
    public let titleText: AttributedString
}
