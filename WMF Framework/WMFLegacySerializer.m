#import <WMF/WMFLegacySerializer.h>
#import <WMF/NSError+WMFExtensions.h>
#import <WMF/WMF-Swift.h>

@implementation WMFLegacySerializer

+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromArrayForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary languageVariantCode:(nullable NSString *)languageVariantCode error:(NSError **)error {
    NSArray *maybeJSONDictionaries = [JSONDictionary valueForKeyPath:keyPath];

    if (![maybeJSONDictionaries isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [WMFFetcher unexpectedResponseError];
        }
        return nil;
    }
    
    return [self modelsOfClass:modelClass fromUntypedArray:maybeJSONDictionaries languageVariantCode: languageVariantCode error:error];
}

// Filters the untyped array to only include NSDictionary objects before serializing into modelClass
+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromUntypedArray:(NSArray *)untypedArray languageVariantCode:(nullable NSString *)languageVariantCode error:(NSError **)error {
    NSArray *JSONDictionaries = [untypedArray wmf_select:^BOOL(id _Nonnull maybeJSONDictionary) {
        return [maybeJSONDictionary isKindOfClass:[NSDictionary class]];
    }];
    
    return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONDictionaries languageVariantCode: languageVariantCode error:error];
}

@end
