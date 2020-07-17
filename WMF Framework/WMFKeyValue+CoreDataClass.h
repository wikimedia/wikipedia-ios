#import <CoreData/CoreData.h>

@class NSObject;

NS_ASSUME_NONNULL_BEGIN

/**
 *  WMFKeyValue is utilized as a key/value store for values related to a user's Core Data library. It can be used for sensitive data that might not be appropriate for NSUserDefaults or anything that is tied to the Core Data library.
 */
@interface WMFKeyValue : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import <WMF/WMFKeyValue+CoreDataProperties.h>
