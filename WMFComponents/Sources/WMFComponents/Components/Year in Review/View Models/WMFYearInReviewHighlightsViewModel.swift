import Foundation

public class WMFYearInReviewSlideHighlightsViewModel {

    func getTableViewModel() -> WMFInfoTableViewModel {
        // mock data
        let item1 = TableItem(title: "Most popular articles on English Wikipedia", text: "1. Pamela Anderson \n2. Pamukkale \n3. History of US science fiction  \n4. Dolphins \n5. Climate change ")
        let item2 = TableItem(title: "Hours spent reading", text: "11111111111")
        let item3 = TableItem(title: "Changes editors made", text: "4234444434343434")
        let item4 = TableItem(title: "Changes editors made", text: "2")

        return WMFInfoTableViewModel(tableItems: [item1, item2, item3, item4])
    }

}
