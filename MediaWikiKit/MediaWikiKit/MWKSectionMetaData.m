
#import "MWKSectionMetaData.h"

@implementation MWKSectionMetaData

+ (NSValueTransformer*)numberJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* value, BOOL* success, NSError* __autoreleasing* error) {
        if (!value) {
            //Summary section return 0 - the first section
            value = @"0";
        }

        NSArray* indexes = [value componentsSeparatedByString:@"."];

        NSIndexPath* indexPath = [indexes bk_reduce:[NSIndexPath new] withBlock:^id (NSIndexPath* sum, NSString* obj) {
            return [sum indexPathByAddingIndex:(NSUInteger)[obj integerValue]];
        }];

        return indexPath;
    }];
}

+ (NSValueTransformer*)levelJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSNumber* value, BOOL* success, NSError* __autoreleasing* error) {
        if (!value) {
            //Summary section return 2 - it is the default level of a section
            value = @2;
        }

        return value;
    }];
}

+ (NSValueTransformer*)displayTitleJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* value, BOOL* success, NSError* __autoreleasing* error) {
        if (!value) {
            //Summary section return "Summary"
            value = @"Summary";
        }

        return value;
    }];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               @"displayTitle": @"line",
               @"level": @"level",
               @"number": @"number",
    };
}

@end
