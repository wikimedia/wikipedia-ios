#import "NSObject+WMFReflection.h"

static inline void objc_propertyListRelease(objc_property_t **objectRef) __attribute__((overloadable));
static inline void objc_propertyListRelease(objc_property_t **objectRef) __attribute__((overloadable)) {
    if (*objectRef != NULL) {
        free((*objectRef));
    }
}

#define freePropertyListOnExit __attribute__((cleanup(objc_propertyListRelease)))

@implementation NSObject (WMFReflection)

+ (void)wmf_enumeratePropertiesUntilSuperclass:(Class)superClass usingBlock:(WMFObjCPropertyEnumerator)block {
    Class cls = self;
    BOOL stop = NO;

    while (!stop && ![cls isEqual:superClass]) {
        unsigned count = 0;
        freePropertyListOnExit objc_property_t *properties = class_copyPropertyList(cls, &count);

        cls = cls.superclass;
        if (properties == NULL) {
            continue;
        }

        for (unsigned i = 0; i < count; i++) {
            block(properties[i], &stop);
            if (stop) {
                break;
            }
        }
    }
}

@end
