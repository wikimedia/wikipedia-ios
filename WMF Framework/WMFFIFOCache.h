#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFFIFOCache <__covariant KeyType, __covariant ObjectType> : NSObject

- (instancetype)initWithCountLimit:(NSUInteger)countLimit NS_DESIGNATED_INITIALIZER;

- (nullable ObjectType)objectForKey:(KeyType)key;
- (void)setObject:(ObjectType)obj forKey:(KeyType)key;
- (void)removeObjectForKey:(KeyType)key;

- (void)removeAllObjects;

@property NSUInteger countLimit;

@end

NS_ASSUME_NONNULL_END
