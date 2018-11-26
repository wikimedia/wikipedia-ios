#import <WMF/WMFLegacySerializer.h>
#import <WMF/NSError+WMFExtensions.h>
#import <Mantle/MTLJSONAdapter.h>
#import <WMF/WMF-Swift.h>

@implementation WMFLegacySerializer

+ (nullable NSArray *)modelsOfClass:(Class)modelClass fromArrayForKeyPath:(NSString *)keyPath inJSONDictionary:(nullable NSDictionary *)JSONDictionary error:(NSError **)error {
    NSArray *maybeJSONDictionaries = [JSONDictionary valueForKeyPath:keyPath];

    if (![maybeJSONDictionaries isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil];
        }
        return nil;
    }
    
    NSArray *JSONDictionaries = [maybeJSONDictionaries wmf_select:^BOOL(id _Nonnull maybeJSONDictionary) {
        return [maybeJSONDictionary isKindOfClass:[NSDictionary class]];
    }];
    
    return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONDictionaries error:error];
}

@end
