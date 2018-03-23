import Foundation

extension ReadingList {
    @objc public static let conflictingReadingListNameUpdatedNotification = NSNotification.Name(rawValue: "WMFConflictingReadingListNameUpdatedNotification")
    @objc public static let conflictingReadingListNameUpdatedOldNameKey = NSNotification.Name(rawValue: "oldName")
    @objc public static let conflictingReadingListNameUpdatedNewNameKey = NSNotification.Name(rawValue: "newName")
    
    func update(with remoteList: APIReadingList) {
        self.readingListID = NSNumber(value: remoteList.id)
        if remoteList.name == CommonStrings.readingListsDefaultListTitle {
            self.name = "\(remoteList.name)_[user created]"
            if let newName = self.name {
                let userInfo = [ReadingList.conflictingReadingListNameUpdatedOldNameKey: remoteList.name, ReadingList.conflictingReadingListNameUpdatedNewNameKey: newName]
                NotificationCenter.default.post(name: ReadingList.conflictingReadingListNameUpdatedNotification, object: nil, userInfo: userInfo)
            }
        } else {
            self.name = remoteList.name
        }
        self.readingListDescription = remoteList.description
        if let createdDate = DateFormatter.wmf_iso8601().date(from: remoteList.created) {
            self.createdDate = createdDate as NSDate
        }
        if let updatedDate = DateFormatter.wmf_iso8601().date(from: remoteList.updated) {
            self.updatedDate = updatedDate as NSDate
        }
        if remoteList.isDefault && !isDefault {
            isDefault = true
        }
        errorCode = nil
        isUpdatedLocally = false
    }
}
