struct RemoteNotificationsModelController {
    let container: NSPersistentContainer

    init?() {
        let modelName = "RemoteNotifications"
        let modelExtension = "momd"
        let modelBundle = Bundle.wmf
        guard let modelURL = modelBundle.url(forResource: modelName, withExtension: modelExtension) else {
            assertionFailure("Couldn't find url for resource named \(modelName) with extension \(modelExtension) in bundle \(modelBundle); make sure you're providing the right name, extension and bundle")
            return nil
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            assertionFailure("Couldn't create model with contents of \(modelURL); make sure \(modelURL) is the correct url for \(modelName)")
            return nil
        }
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let sharedAppContainerURL = FileManager.default.wmf_containerURL()
        let remoteNotificationsStorageURL = sharedAppContainerURL.appendingPathComponent(modelName)
        let description = NSPersistentStoreDescription(url: remoteNotificationsStorageURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                assertionFailure() // TODO
            } else {
                print(storeDescription)
            }
        }
    }
}
