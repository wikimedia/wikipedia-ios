#import "MWKSectionMetaData.h"
#import "MTLValueTransformer+WMFNumericValueTransformer.h"
#import <WMF/WMF-Swift.h>

@implementation MWKSectionMetaData

+ (NSValueTransformer *)numberJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        NSArray *indexes = [value componentsSeparatedByString:@"."];

        NSIndexPath *indexPath = [indexes wmf_reduce:[NSIndexPath new]
                                          withBlock:^id(NSIndexPath *sum, NSString *obj) {
                                              return [sum indexPathByAddingIndex:(NSUInteger)[obj integerValue]];
                                          }];

        return indexPath;
    }];
}

+ (NSValueTransformer *)levelJSONTransformer {
    return [MTLValueTransformer wmf_numericValueTransformer];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"displayTitle": @"line",
        @"level": @"level",
        @"number": @"number",
    };
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //Setting defaults
        _number = [NSIndexPath indexPathWithIndex:0];
        _level = @2;
        _displayTitle = @"Summary";
    }
    return self;
}

@end
