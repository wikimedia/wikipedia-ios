#import "WMFCVLAttributes.h"

@implementation WMFCVLAttributes

- (id)copyWithZone:(nullable NSZone *)zone {
    id copy = [super copyWithZone:zone];
    [copy setPrecalculated:self.precalculated];
    return copy;
}

@end
