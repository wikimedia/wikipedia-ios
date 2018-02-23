import Foundation

extension ReadingListEntry {
    func update(with remoteEntry: APIReadingListEntry) {
        readingListEntryID = NSNumber(value: remoteEntry.id)
        let remoteCreatedDate = DateFormatter.wmf_iso8601().date(from: remoteEntry.created)
        createdDate = remoteCreatedDate as NSDate?
        let remoteUpdatedDate = DateFormatter.wmf_iso8601().date(from: remoteEntry.updated)
        updatedDate = remoteUpdatedDate as NSDate?
        errorCode = nil
        isUpdatedLocally = false
    }
}


