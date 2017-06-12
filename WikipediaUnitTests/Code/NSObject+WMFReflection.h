#import <objc/runtime.h>

typedef void (^WMFObjCPropertyEnumerator)(objc_property_t, BOOL *stop);

/**
 *  Reflection utilities inspired by Mantle's runtime methods.
 */
@interface NSObject (WMFReflection)

+ (void)wmf_enumeratePropertiesUntilSuperclass:(Class)superClass usingBlock:(WMFObjCPropertyEnumerator)block;

@end
