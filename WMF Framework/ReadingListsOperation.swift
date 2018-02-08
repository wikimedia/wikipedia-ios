internal class ReadingListsOperation: AsyncOperation {
    internal weak var readingListsController: ReadingListsController!
    
    internal var apiController: ReadingListsAPIController {
        return readingListsController.apiController
    }
    
    internal var dataStore: MWKDataStore {
        return readingListsController.dataStore
    }
    
    init(readingListsController: ReadingListsController) {
        self.readingListsController = readingListsController
        super.init()
    }
}
