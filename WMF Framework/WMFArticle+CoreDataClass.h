#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN
@class ReadingList;

@interface WMFArticle : NSManagedObject

@property (atomic, readonly) NSArray<ReadingList *> *sortedNonDefaultReadingLists;

@end

NS_ASSUME_NONNULL_END

#import <WMF/WMFArticle+CoreDataProperties.h>
