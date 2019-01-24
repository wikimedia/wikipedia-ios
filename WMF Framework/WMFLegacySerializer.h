#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFLegacySerializer : NSObject

// Serializes {-object-}s at "key.path" in the form {"key": {"path": [{-object-}, {-object-}]}}
+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromArrayForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary error:(NSError **)error;

// Serializes {-object-}s at "key.path" in the form {"key": {"path": {"a": {-object-}, "b": {-object-}}}}
+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromAllValuesOfDictionaryForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary error:(NSError **)error;

// Filters the untyped array to only include NSDictionary objects before serializing into modelClass
+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromUntypedArray:(NSArray *)untypedArray error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
