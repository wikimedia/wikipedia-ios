#import <WMF/WMFLegacySerializer.h>
#import <WMF/NSError+WMFExtensions.h>
#import <Mantle/MTLJSONAdapter.h>
#import <WMF/WMF-Swift.h>

@implementation WMFLegacySerializer

+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromArrayForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary error:(NSError **)error {
    NSArray *maybeJSONDictionaries = [JSONDictionary valueForKeyPath:keyPath];

    if (![maybeJSONDictionaries isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [WMFFetcher unexpectedResponseError];
        }
        return nil;
    }
    
    return [self modelsOfClass:modelClass fromUntypedArray:maybeJSONDictionaries error:error];
}

+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromAllValuesOfDictionaryForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary error:(NSError **)error {
    NSDictionary *maybeJSONDictionaries = [JSONDictionary valueForKeyPath:keyPath];
    
    if (![maybeJSONDictionaries isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [WMFFetcher unexpectedResponseError];
        }
        return nil;
    }
    
    return [self modelsOfClass:modelClass fromUntypedArray:[maybeJSONDictionaries allValues] error:error];
}

+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromUntypedArray:(NSArray *)untypedArray error:(NSError **)error {
    NSArray *JSONDictionaries = [untypedArray wmf_select:^BOOL(id _Nonnull maybeJSONDictionary) {
        return [maybeJSONDictionary isKindOfClass:[NSDictionary class]];
    }];
    
    return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONDictionaries error:error];
}

@end
