import SwiftUI

@MainActor
class DatabasePopulationViewModel: ObservableObject {
    @Published var createLists: Bool = false
    @Published var addEntries: Bool = false
    @Published var randomizeAcrossLanguages: Bool = false

    @Published var listLimitString: String
    @Published var entryLimitString: String

    @Published var isLoading = false

    init() {
        let moc = MWKDataStore.shared().viewContext
        let savedLists = moc.wmf_numberValue(forKey: "WMFCountOfListsToCreate")?.intValue ?? 10
        let savedEntries = moc.wmf_numberValue(forKey: "WMFCountOfEntriesToCreate")?.intValue ?? 100

        listLimitString = "\(savedLists)"
        entryLimitString = "\(savedEntries)"
    }

    var listLimit: Int64 { Int64(listLimitString) ?? 10 }
    var entryLimit: Int64 { Int64(entryLimitString) ?? 100 }

    func doIt() async {
        isLoading = true

        let dataStore = MWKDataStore.shared()
        let controller = dataStore.readingListsController

        await withCheckedContinuation { continuation in
            controller.debugSync(
                createLists: createLists,
                listCount: listLimit,
                addEntries: addEntries,
                randomizeLanguageEntries: randomizeAcrossLanguages,
                entryCount: entryLimit
            ) {
                continuation.resume()
            }
        }

        isLoading = false
    }
}
