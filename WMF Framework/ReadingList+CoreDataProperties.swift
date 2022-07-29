import Foundation
import CoreData

extension ReadingList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingList> {
        return NSFetchRequest<ReadingList>(entityName: "ReadingList")
    }

    @NSManaged public var canonicalName: String?
    @NSManaged public var color: String?
    @NSManaged public var countOfEntries: Int64
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var errorCode: String?
    @NSManaged public var iconName: String?
    @NSManaged public var imageName: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var isDeletedLocally: Bool
    @NSManaged public var isUpdatedLocally: Bool
    @NSManaged public var readingListDescription: String?
    @NSManaged public var readingListID: NSNumber?
    @NSManaged public var updatedDate: NSDate?
    @NSManaged public var articles: Set<WMFArticle>?
    @NSManaged public var entries: Set<ReadingListEntry>?
    @NSManaged public var previewArticles: NSOrderedSet?
    @NSManaged public var sortOrder: NSNumber?
    
    public var name: String? {
        get {
            return isDefault ? CommonStrings.readingListsDefaultListTitle : canonicalName
        }
        set {
            canonicalName = newValue?.precomposedStringWithCanonicalMapping
        }
    }
    
    public var APIError: APIReadingListError? {
        guard let errorCode = errorCode ?? entries?.first(where: { !$0.isDeletedLocally && $0.errorCode != nil })?.errorCode else {
            return nil
        }
        return APIReadingListError(rawValue: errorCode)
    }
    
    @objc static let defaultListCanonicalName = "default"

}

// MARK: Generated accessors for articles
extension ReadingList {

    @objc(addArticlesObject:)
    @NSManaged public func addToArticles(_ value: WMFArticle)

    @objc(removeArticlesObject:)
    @NSManaged public func removeFromArticles(_ value: WMFArticle)

    @objc(addArticles:)
    @NSManaged public func addToArticles(_ values: NSSet)

    @objc(removeArticles:)
    @NSManaged public func removeFromArticles(_ values: NSSet)

}

// MARK: Generated accessors for entries
extension ReadingList {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: ReadingListEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: ReadingListEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

// MARK: Generated accessors for previewArticles
extension ReadingList {

    @objc(insertObject:inPreviewArticlesAtIndex:)
    @NSManaged public func insertIntoPreviewArticles(_ value: WMFArticle, at idx: Int)

    @objc(removeObjectFromPreviewArticlesAtIndex:)
    @NSManaged public func removeFromPreviewArticles(at idx: Int)

    @objc(insertPreviewArticles:atIndexes:)
    @NSManaged public func insertIntoPreviewArticles(_ values: [WMFArticle], at indexes: NSIndexSet)

    @objc(removePreviewArticlesAtIndexes:)
    @NSManaged public func removeFromPreviewArticles(at indexes: NSIndexSet)

    @objc(replaceObjectInPreviewArticlesAtIndex:withObject:)
    @NSManaged public func replacePreviewArticles(at idx: Int, with value: WMFArticle)

    @objc(replacePreviewArticlesAtIndexes:withPreviewArticles:)
    @NSManaged public func replacePreviewArticles(at indexes: NSIndexSet, with values: [WMFArticle])

    @objc(addPreviewArticlesObject:)
    @NSManaged public func addToPreviewArticles(_ value: WMFArticle)

    @objc(removePreviewArticlesObject:)
    @NSManaged public func removeFromPreviewArticles(_ value: WMFArticle)

    @objc(addPreviewArticles:)
    @NSManaged public func addToPreviewArticles(_ values: NSOrderedSet)

    @objc(removePreviewArticles:)
    @NSManaged public func removeFromPreviewArticles(_ values: NSOrderedSet)

}
