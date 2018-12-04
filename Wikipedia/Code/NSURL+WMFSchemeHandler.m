#import <WMF/NSURL+WMFSchemeHandler.h>
#import <WMF/NSURL+WMFQueryParameters.h>

NSString *const WMFAppSchemeImageOriginalSrcKey = @"originalSrc";
NSString *const WMFAppSchemeImageBasePath = @"imageProxy";
NSString *const WMFAppSchemeFileBasePath = @"fileProxy";
NSString *const WMFAppSchemeAPIBasePath = @"APIProxy";

@implementation NSURL (WMFSchemeHandler)

- (nullable NSURL *)wmf_imageAppSchemeOriginalSrcURL {
    return [NSURL URLWithString:[self wmf_valueForQueryKey:WMFAppSchemeImageOriginalSrcKey]];
}

- (NSURL *)wmf_imageAppSchemeURLWithOriginalSrc:(NSString *)originalSrc {
    return [self wmf_urlWithValue:originalSrc forQueryKey:WMFAppSchemeImageOriginalSrcKey];
}

@end
