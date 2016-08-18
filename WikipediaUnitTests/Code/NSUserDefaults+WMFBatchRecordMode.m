
#import "NSUserDefaults+WMFBatchRecordMode.h"

@implementation NSUserDefaults (WMFBatchRecordMode)

- (BOOL)wmf_visualTestBatchRecordMode {
    return [self boolForKey:@"WMFVisualTestBatchRecordMode"];
}

@end
