@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (WMFExtensions)

/**
 *  @return objectForKey if it isKindOf objectClass, nil otherwise
 */
- (nullable ObjectType)wmf_objectOfClass:(Class)objectClass forKey:(KeyType)key;

/**
 *  @return objectForKey if it is an NSString, nil otherwise
 */
- (nullable NSString *)wmf_stringForKey:(KeyType)key;

/**
 *  @return objectForKey if it is an NSDictionary, nil otherwise
 */
- (nullable NSDictionary *)wmf_dictionaryForKey:(KeyType)key;

/**
 *  @return objectForKey if it is an NSNumber, nil otherwise
 */
- (nullable NSNumber *)wmf_numberForKey:(KeyType)key;


/**
 *  @return objectForKey if it is an NSString that can be converted into a NSURL, nil otherwise
 */
- (nullable NSURL *)wmf_URLFromStringForKey:(KeyType)key;

/**
 *  Used to find dictionaries that contain Nulls
 *
 *  @return YES if any objects are [NSNull null], otherwise NO
 */
- (BOOL)wmf_containsNullObjects;

/**
 *  Used to find dictionaries that contain Nulls or contain sub-dictionaries or arrays that contain Nulls
 *
 *  @return YES if any objects or sub-collection objects are [NSNull null], otherwise NO
 */
- (BOOL)wmf_recursivelyContainsNullObjects;

/**
 *  Remove Nulls from a dictionary before returning it
 *
 *  @return A dictionary without any [NSNull nulls]
 */
- (nullable NSDictionary *)wmf_dictionaryByRemovingNullObjects;

@end

NS_ASSUME_NONNULL_END
