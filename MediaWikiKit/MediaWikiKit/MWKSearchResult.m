
#import "MWKSearchResult.h"
#import "NSURL+Extras.h"
#import "NSString+Extras.h"
#import "NSString+WMFHTMLParsing.h"

@implementation MWKSearchResult

+ (NSValueTransformer*)thumbnailURLJSONTransformer {
    return [MTLValueTransformer
            transformerUsingForwardBlock:^NSURL* (NSString* urlString,
                                                  BOOL* success,
                                                  NSError* __autoreleasing* error) {
        return [NSURL wmf_optionalURLWithString:urlString];
    }
                            reverseBlock:^NSString* (NSURL* thumbnailURL,
                                                     BOOL* success,
                                                     NSError* __autoreleasing* error) {
        return [thumbnailURL absoluteString];
    }];
}

+ (NSValueTransformer*)wikidataDescriptionJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        NSString* description = [value firstObject];
        return [description wmf_stringByCapitalizingFirstCharacter];
    }];
}

+ (MTLValueTransformer*)extractJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* extract, BOOL* success, NSError* __autoreleasing* error) {
        return [extract wmf_summaryFromText];
    }];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               WMF_SAFE_KEYPATH(MWKSearchResult.new, displayTitle): @"title",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, articleID): @"pageid",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, thumbnailURL): @"thumbnail.source",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, wikidataDescription): @"terms.description",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, extract): @"extract",
               WMF_SAFE_KEYPATH(MWKSearchResult.new, index): @"index"
    };
}

@end
