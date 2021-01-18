#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFLegacySerializer : NSObject

// Serializes {-object-}s at "key.path" in the form {"key": {"path": [{-object-}, {-object-}]}}
// The languageVariantCode is propogated to the URL properties of the graph of deserialized model objects
+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromArrayForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary languageVariantCode:(nullable NSString *)languageVariantCode error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
