#import <WMF/NSManagedObjectContext+WMFKeyValue.h>
#import <WMF/WMFKeyValue+CoreDataProperties.h>
#import <WMF/WMFLogging.h>

@implementation NSManagedObjectContext (WMFKeyValue)

- (nullable NSArray<WMFKeyValue *> *)wmf_keyValuesForKey:(NSString *)key fetchLimit:(NSInteger)fetchLimit {
    NSFetchRequest *request = [WMFKeyValue fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
    if (fetchLimit > 0) {
        request.fetchLimit = fetchLimit;
    }
    NSError *keyValueFetchError = nil;
    NSArray<WMFKeyValue *> *results = [self executeFetchRequest:request error:&keyValueFetchError];
    if (keyValueFetchError) {
        DDLogError(@"Error fetching key value: %@", keyValueFetchError);
    }
    return results;
}
- (nullable WMFKeyValue *)wmf_keyValueForKey:(NSString *)key {
    NSArray<WMFKeyValue *> *results = [self wmf_keyValuesForKey:key fetchLimit:1];
    return results.firstObject;
}

- (nullable id)wmf_valueOfClass:(Class) class forKey:(NSString *)key {
    WMFKeyValue *keyValue = [self wmf_keyValueForKey:key];
    id value = keyValue.value;
    if ([value isKindOfClass:class]) {
        return value;
    } else {
        return nil;
    }
}

    - (nullable NSNumber *)wmf_numberValueForKey : (NSString *)key {
    return [self wmf_valueOfClass:[NSNumber class] forKey:key];
}

- (nullable NSString *)wmf_stringValueForKey:(NSString *)key {
    return [self wmf_valueOfClass:[NSString class] forKey:key];
}

- (nullable NSArray *)wmf_arrayValueForKey:(NSString *)key {
    return [self wmf_valueOfClass:[NSArray class] forKey:key];
}

- (WMFKeyValue *)wmf_setValue:(nullable id<NSCoding>)value forKey:(NSString *)key {
    NSArray<WMFKeyValue *> *results = [self wmf_keyValuesForKey:key fetchLimit:0];
    if (results.count > 1) {
        // failsafe to delete extra key value objects
        NSArray<WMFKeyValue *> *subarray = [results subarrayWithRange:NSMakeRange(1, results.count - 1)];
        for (WMFKeyValue *value in subarray) {
            [self deleteObject:value];
        }
    }
    WMFKeyValue *keyValue = results.firstObject;
    if (!keyValue) {
        keyValue = [NSEntityDescription insertNewObjectForEntityForName:@"WMFKeyValue" inManagedObjectContext:self];
        keyValue.key = key;
    }
    keyValue.value = value;
    return keyValue;
}

@end
