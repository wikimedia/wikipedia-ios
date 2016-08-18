#import "WMFRandomFileUtilities.h"

NSString *WMFRandomTemporaryPath() {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
}

NSString *WMFRandomTemporaryFileOfType(NSString *extension) {
    return [WMFRandomTemporaryPath() stringByAppendingPathExtension:extension];
}