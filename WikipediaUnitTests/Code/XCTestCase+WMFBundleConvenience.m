#import "XCTestCase+WMFBundleConvenience.h"

@implementation XCTestCase (WMFBundleConvenience)

- (NSBundle *)wmf_bundle {
    return [NSBundle bundleForClass:[self class]];
}

@end
