import Foundation

public class WMFInfoboxViewModel {
    let tableItems: [TableItem]

    public init(tableItems: [TableItem]) {
        self.tableItems = tableItems
    }

}

public struct TableItem {
    public let title: String
    public let text: String
}
