#ifndef Wikipedia_WMFComparison_h
#define Wikipedia_WMFComparison_h

/**
 * Provides compile time checking for keypaths on a given object.
 * @discussion Example usage:
 *
 *      WMF_SAFE_KEYPATH([NSString new], lowercaseString); //< @"lowercaseString"
 *      WMF_SAFE_KEYPATH([NSString new], fooBar); //< compiler error!
 *
 * @note Inspired by [EXTKeypathCoding.h](https://github.com/jspahrsummers/libextobjc/blob/master/extobjc/EXTKeyPathCoding.h#L14)
 */
#define WMF_SAFE_KEYPATH(obj, keyp) ((NO, (void)obj.keyp), @ #keyp)

/**
 * Compare two *objects* using `==` and <code>[a sel b]</code>, where `sel` is an equality selector
 * (e.g. `isEqualToString:`).
 * @param a   First object, can be `nil`.
 * @param sel The selector used to compare @c a to @c b, if <code>a == b</code> is @c false.
 * @param b   Second object, can be `nil`.
 * @return `YES` if the objects are the same pointer or invoking @c sel returns @c YES, otherwise @c NO.
 */
#define WMF_EQUAL(a, sel, b) (((a) == (b)) || ([(a)sel(b)]))

/**
 * Check if two objects have the same value for given property.
 * @param a     First object, can be @c nil.
 * @param prop  The property whose value is accessed from `a` and `b`, e.g. `count`.
 * @param sel   The selector used to compare `a.prop` to `b.prop`.
 * @param b     Second object, can be @c nil.
 * @return `YES` if the values are equal or both `nil`, otherwise `NO`.
 * @see WMF_EQUAL
 */
#define WMF_EQUAL_PROPERTIES(a, prop, sel, b) WMF_EQUAL([(a)prop], sel, [(b)prop])

/// Convenience for `WMF_EQUAL_PROPERTIES` which passes `isEqual:` for the equality selector.
#define WMF_IS_EQUAL_PROPERTIES(a, prop, b) WMF_EQUAL_PROPERTIES(a, prop, isEqual:, b)

/**
 * Compare two objects using `==` and `isEqual:`.
 * @see WMF_EQUAL
 */
#define WMF_IS_EQUAL(a, b) (WMF_EQUAL(a, isEqual:, b))

#ifndef WMF_RHS_VARNAME
#define WMF_RHS_VARNAME rhs
#endif

/**
 * Compare if the values returned by @c prop are equal for @c self and @c rhs using @c sel
 * @param prop  The property to compare (should be a getter instance method).
 * @param sel   The selector to use when comparing values returned by @c prop.
 * @return @c YES if the values returned by @c prop for @c self and @c rhs are equal.
 */
#define WMF_RHS_PROP_EQUAL(prop, sel) WMF_EQUAL_PROPERTIES(self, prop, sel, rhs)

#define WMF_SYNTHESIZE_IS_EQUAL(CLASS_NAME, CLASS_EQ_SEL)                                                    \
    -(BOOL)isEqual : (id)obj {                                                                               \
        return [super isEqual:obj] || [obj isKindOfClass:[CLASS_NAME class]] ? [self CLASS_EQ_SEL obj] : NO; \
    }

#endif
