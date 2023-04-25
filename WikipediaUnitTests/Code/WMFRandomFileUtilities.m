#import "WMFRandomFileUtilities.h"

NSString *WMFRandomTemporaryPath(void) {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
}

NSString *WMFRandomTemporaryFileOfType(NSString *extension) {
    return [WMFRandomTemporaryPath() stringByAppendingPathExtension:extension];
}
