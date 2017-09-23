@import Foundation;

@interface NSObject (WMFMethodSwizzling)

/**
 * Replaces original selector to a new selector.
 * @param originalSelector The original selector.
 * @param swizzledSelector The new selector.
 * @warning Please, don't use this method if you aren't sure that you have a
 * strong understanding how it works!
 */
+ (void)wmf_swizzleOriginalSelector:(SEL)originalSelector
                 toSwizzledSelector:(SEL)swizzledSelector;

@end
