
#import "MWKSearchResult.h"
#import "NSURL+Extras.h"
#import "NSString+Extras.h"

@implementation MWKSearchResult

+ (NSValueTransformer*)thumbnailURLJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* value, BOOL* success, NSError* __autoreleasing* error) {
        return [NSURL wmf_optionalURLWithString:value];
    }];
}

+ (NSValueTransformer*)wikidataDescriptionJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        NSString* description = [value firstObject];
        return [description wmf_stringByCapitalizingFirstCharacter];
    }];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               WMF_SAFE_KEYPATH(MWKSearchResult.new, displayTitle): @"title",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, articleID): @"pageid",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, thumbnailURL): @"thumbnail.source",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, wikidataDescription): @"terms.description"
    };
}

@end
