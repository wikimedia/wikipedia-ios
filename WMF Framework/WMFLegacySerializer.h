#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFLegacySerializer : NSObject

+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromArrayForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
