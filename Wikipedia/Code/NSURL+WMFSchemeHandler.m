#import <WMF/NSURL+WMFSchemeHandler.h>
#import <WMF/NSURL+WMFQueryParameters.h>

NSString *const WMFLegacyURLSchemeHandlerScheme = @"wmfapp";
NSString *const WMFURLSchemeHandlerScheme = @"app";

@implementation NSURL (WMFSchemeHandler)

- (nullable NSURL *)wmf_originalURLFromAppSchemeURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.scheme = @"https";
    return [components URL];
}

+ (NSURL *)wmf_legacyAppSchemeURLForURLString:(NSString *)URLString {
    NSURLComponents *components = [NSURLComponents componentsWithString:URLString];
    components.scheme = WMFLegacyURLSchemeHandlerScheme;
    return components.URL;
}

+ (NSURL *)wmf_appSchemeURLForURLString:(NSString *)URLString {
    NSURLComponents *components = [NSURLComponents componentsWithString:URLString];
    components.scheme = WMFURLSchemeHandlerScheme;
    return components.URL;
}

@end
