//
//  MWKArticlePreview.m
//
//
//  Created by Corey Floyd on 7/27/15.
//
//

#import "MWKArticlePreview.h"
#import "NSDateFormatter+WMFExtensions.h"

@implementation MWKArticlePreview

#pragma mark - JSON

+ (NSValueTransformer*)htmlSummaryJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        return [value firstObject][@"text"];
    }];
}

+ (NSValueTransformer*)sectionTitlesJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        return [value bk_map:^id (NSDictionary* obj) {
            NSString* title = obj[@"line"];
            if (!title) {
                title = @"Summary";
            }
            return title;
        }];
    }];
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
               @"wikidataDescription": @"description",
               @"htmlSummary": @"sections",
               @"sectionTitles": @"sections",
               @"lastModified": @"lastmodified",
               //When MWKUser inherits from MTLModel, we can use it and the dictionaryTransformerWithModelClass API instead
               @"lastModifiedBy": @"lastmodifiedby.name",
    };
}

@end
