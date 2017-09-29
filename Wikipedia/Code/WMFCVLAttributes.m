#import "WMFCVLAttributes.h"

@implementation WMFCVLAttributes

- (id)copyWithZone:(nullable NSZone *)zone {
    id copy = [super copyWithZone:zone];
    [copy setPrecalculated:self.precalculated];
    [copy setReadableMargins:self.readableMargins];
    return copy;
}

@end
