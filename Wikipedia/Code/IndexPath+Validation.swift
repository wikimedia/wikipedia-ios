public extension IndexPath {
    func isValid<T: NSManagedObject>(in fetchedResultsController: NSFetchedResultsController<T>?) -> Bool {
        guard let sections = fetchedResultsController?.sections,
            section < sections.count,
            item < sections[section].numberOfObjects else {
                return false
        }
        return true
    }
}
