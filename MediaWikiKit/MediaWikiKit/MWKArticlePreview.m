
#import "MWKArticlePreview.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "MWKSectionMetaData.h"

@implementation MWKArticlePreview

#pragma mark - JSON

+ (NSValueTransformer*)htmlSummaryJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        return [value firstObject][@"text"];
    }];
}

+ (NSValueTransformer*)sectionsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[MWKSectionMetaData class]];
}

+ (NSValueTransformer*)lastModifiedJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* value, BOOL* success, NSError* __autoreleasing* error) {
        return [[NSDateFormatter wmf_iso8601Formatter] dateFromString:value];
    }];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               @"numberOfLanguages": @"languagecount",
               @"displayTitle": @"displaytitle",
               @"articleID": @"id",
               @"sections": @"sections",
               @"wikidataDescription": @"description",
               @"htmlSummary": @"sections",
               @"lastModified": @"lastmodified",
               //When MWKUser inherits from MTLModel, we can use it and the dictionaryTransformerWithModelClass API instead
               @"lastModifiedBy": @"lastmodifiedby.name",
    };
}

@end
