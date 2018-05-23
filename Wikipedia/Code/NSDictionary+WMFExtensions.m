#import <WMF/NSDictionary+WMFExtensions.h>
#import <WMF/WMF-Swift.h>

@implementation NSDictionary (WMFExtensions)

- (nullable id)wmf_objectOfClass:(Class)objectClass forKey:(id)key {
    id value = [self objectForKey:key];
    if (![value isKindOfClass:objectClass]) {
        return nil;
    }
    return value;
}

- (nullable NSString *)wmf_stringForKey:(id)key {
    return [self wmf_objectOfClass:[NSString class] forKey:key];
}

- (nullable NSDictionary *)wmf_dictionaryForKey:(id)key {
    return [self wmf_objectOfClass:[NSDictionary class] forKey:key];
}

- (nullable NSNumber *)wmf_numberForKey:(id)key {
    return [self wmf_objectOfClass:[NSNumber class] forKey:key];
}

- (nullable NSURL *)wmf_URLFromStringForKey:(id)key {
    NSString *URLString = [self wmf_stringForKey:key];
    if (!URLString) {
        return nil;
    }
    return [NSURL URLWithString:URLString];
}

- (BOOL)wmf_containsNullObjects {
    NSNull *null = [self wmf_match:^BOOL(id key, id obj) {
        return [obj isKindOfClass:[NSNull class]];
    }];
    return (null != nil);
}

- (BOOL)wmf_recursivelyContainsNullObjects {

    if ([self wmf_containsNullObjects]) {
        return YES;
    }

    __block BOOL hasNull = NO;
    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {

        if ([obj isKindOfClass:[NSDictionary class]]) {

            hasNull = [obj wmf_recursivelyContainsNullObjects];
            if (hasNull) {
                *stop = YES;
                return;
            }
        }

        if ([obj isKindOfClass:[NSArray class]]) {

            hasNull = [obj wmf_recursivelyContainsNullObjects];
            if (hasNull) {
                *stop = YES;
                return;
            }
        }

    }];

    return hasNull;
}

- (NSDictionary *)wmf_dictionaryByRemovingNullObjects {
    return [self wmf_reject:^BOOL(id key, id obj) {
        return obj == [NSNull null];
    }];
}

@end
