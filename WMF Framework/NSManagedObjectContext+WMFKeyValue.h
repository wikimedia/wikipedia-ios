#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class WMFKeyValue;

@interface NSManagedObjectContext (WMFKeyValue)

- (nullable WMFKeyValue *)wmf_keyValueForKey:(NSString *)key;
- (nullable NSNumber *)wmf_numberValueForKey:(NSString *)key;
- (nullable NSString *)wmf_stringValueForKey:(NSString *)key;
- (nullable NSArray *)wmf_arrayValueForKey:(NSString *)key;

- (WMFKeyValue *)wmf_setValue:(nullable id<NSCoding>)value forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
