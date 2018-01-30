class ReadingListsOperation: AsyncOperation {
    weak var readingListsController: ReadingListsController!
    
    var apiController: ReadingListsAPIController {
        return readingListsController.apiController
    }
    
    var dataStore: MWKDataStore {
        return readingListsController.dataStore
    }
    
    init(readingListsController: ReadingListsController) {
        self.readingListsController = readingListsController
        super.init()
    }
}
