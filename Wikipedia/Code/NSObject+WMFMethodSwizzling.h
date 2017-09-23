@import Foundation;

@interface NSObject (WMFMethodSwizzling)

+ (void)wmf_swizzleOriginalSelector:(SEL)originalSelector
                 toSwizzledSelector:(SEL)swizzledSelector;

@end
