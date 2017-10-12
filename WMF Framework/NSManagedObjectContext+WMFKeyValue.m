#import <WMF/NSManagedObjectContext+WMFKeyValue.h>
#import <WMF/WMFKeyValue+CoreDataProperties.h>
#import <WMF/WMFLogging.h>

@implementation NSManagedObjectContext (WMFKeyValue)

- (nullable WMFKeyValue *)wmf_keyValueForKey:(NSString *)key {
    NSFetchRequest *request = [WMFKeyValue fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
    request.fetchLimit = 1;
    NSError *keyValueFetchError = nil;
    NSArray<WMFKeyValue *> *results = [self executeFetchRequest:request error:&keyValueFetchError];
    if (keyValueFetchError) {
        DDLogError(@"Error fetching key value: %@", keyValueFetchError);
    }
    return results.firstObject;
}

- (nullable NSNumber *)wmf_valueOfClass:(Class)class forKey:(NSString *)key {
    WMFKeyValue *keyValue = [self wmf_keyValueForKey:key];
    id value = keyValue.value;
    if ([value isKindOfClass:class]) {
        return value;
    } else {
        return nil;
    }
}

- (nullable NSNumber *)wmf_numberValueForKey:(NSString *)key {
    return [self wmf_valueOfClass:[NSNumber class] forKey:key];
}

- (WMFKeyValue *)wmf_setValue:(id<NSCoding>)value forKey:(NSString *)key {
    WMFKeyValue *keyValue = [self wmf_keyValueForKey:key];
    if (!keyValue) {
        keyValue = [NSEntityDescription insertNewObjectForEntityForName:@"WMFKeyValue" inManagedObjectContext:self];
        keyValue.key = key;
    }
    keyValue.value = value;
    return keyValue;
}

@end
