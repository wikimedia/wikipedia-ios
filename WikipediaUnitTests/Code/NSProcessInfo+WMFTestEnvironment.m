#import "NSProcessInfo+WMFTestEnvironment.h"

@implementation NSProcessInfo (WMFTestEnvironment)

- (BOOL)wmf_isTravis {
    return self.environment[@"TRAVIS"].length > 0;
}

@end
