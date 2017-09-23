#import "NSObject+WMFMethodSwizzling.h"
#import <objc/runtime.h>

@implementation NSObject (WMFMethodSwizzling)

+ (void)wmf_swizzleOriginalSelector:(SEL)originalSelector
                 toSwizzledSelector:(SEL)swizzledSelector {
    NSParameterAssert(originalSelector);
    NSParameterAssert(swizzledSelector);
    
    Method originalMethod = class_getInstanceMethod([self class], originalSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    if (class_addMethod([self class],
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        
        class_replaceMethod([self class],
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
