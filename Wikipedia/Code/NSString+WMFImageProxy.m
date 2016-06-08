#import "NSString+WMFImageProxy.h"
#import "NSString+WMFExtras.h"

@implementation NSString (WMFImageProxy)

- (NSString*)wmf_stringWithLocalhostProxyPrefix {
    NSString* string = [self copy];
    if ([string hasPrefix:@"https:"]) {
        string = [self wmf_safeSubstringFromIndex:6];
    }

    return [NSString stringWithFormat:@"http://localhost:8080/imageProxy?originalSrc=%@", [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString*)wmf_srcsetValueWithLocalhostProxyPrefixes {
    NSArray* pairs         = [self componentsSeparatedByString:@","];
    NSMutableArray* output = [[NSMutableArray alloc] init];
    for (NSString* pair in pairs) {
        NSString* trimmedPair = [pair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray* parts        = [trimmedPair componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (parts.count == 2) {
            NSString* url     = parts[0];
            NSString* density = parts[1];
            [output addObject:[NSString stringWithFormat:@"%@ %@", [url wmf_stringWithLocalhostProxyPrefix], density]];
        } else {
            [output addObject:pair];
        }
    }
    return [output componentsJoinedByString:@", "];
}

@end
