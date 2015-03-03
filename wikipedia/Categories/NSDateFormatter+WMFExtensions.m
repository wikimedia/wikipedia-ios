
#import "NSDateFormatter+WMFExtensions.h"

@implementation NSDateFormatter (WMFExtensions)

+ (NSDateFormatter*)wmf_iso8601Formatter {
    static NSDateFormatter* _formatter = nil;

    if (!_formatter) {
        // See: https://www.mediawiki.org/wiki/Manual:WfTimestamp
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [_formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }

    return _formatter;
}

@end
