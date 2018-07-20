public extension NSFetchedResultsController {
    @objc func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        guard let sections = sections,
        indexPath.section < sections.count,
        indexPath.item < sections[indexPath.section].numberOfObjects else {
            return false
        }
        return true
    }
}
