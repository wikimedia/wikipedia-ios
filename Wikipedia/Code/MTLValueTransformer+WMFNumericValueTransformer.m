#import "MTLValueTransformer+WMFNumericValueTransformer.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
@import WMF.WMFOutParamUtils;

static NSString *const WMFNumericTransformerErrorDomain = @"WMFNumericTransformerErrorDomain";

typedef NS_ENUM(NSInteger, WMFNumericTransformerErrorCode) {
    WMFNumericTransformerErrorDomainInvalidString
};

@implementation MTLValueTransformer (WMFNumericValueTransformer)

+ (instancetype)wmf_numericValueTransformer {
    NSValueTransformer<MTLTransformerErrorHandling> *validatingNumberTransformer =
        [MTLValueTransformer mtl_validatingTransformerForClass:[NSNumber class]];
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id stringOrNumber, BOOL *success, NSError *__autoreleasing *error) {
        if ([stringOrNumber isKindOfClass:[NSString class]]) {
            double value = 0.0;
            if ([[NSScanner scannerWithString:stringOrNumber] scanDouble:&value]) {
                return @(value);
            } else {
                *success = NO;
                WMFSafeAssign(error,
                              [NSError errorWithDomain:WMFNumericTransformerErrorDomain
                                                  code:WMFNumericTransformerErrorDomainInvalidString
                                              userInfo:nil]);
                return nil;
            }
        } else {
            return [validatingNumberTransformer transformedValue:stringOrNumber success:success error:error];
        }
    }];
}

@end
