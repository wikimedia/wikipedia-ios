import Foundation

public class OLDWMFInfoboxViewModel {
    let logoCaption: String
    let tableItems: [OLDTableItem]

    public init(logoCaption: String, tableItems: [OLDTableItem]) {
        self.logoCaption = logoCaption
        self.tableItems = tableItems
    }
}

public struct OLDTableItem {
    public let title: String

    public let text: String?
    public let richRows: [OLDInfoboxRichRow]?

    public init(title: String, text: String) {
        self.title = title
        self.text = text
        self.richRows = nil
    }

    public init(title: String, richRows: [OLDInfoboxRichRow]) {
        self.title = title
        self.text = nil
        self.richRows = richRows
    }
}

public struct OLDInfoboxRichRow: Identifiable {
    public let id = UUID()
    public let numberText: AttributedString
    public let titleText: AttributedString
}
