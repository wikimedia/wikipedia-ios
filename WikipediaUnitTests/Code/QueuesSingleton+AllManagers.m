#import "QueuesSingleton+AllManagers.h"
#import "NSObject+WMFReflection.h"

@implementation QueuesSingleton (AllManagers)

- (NSArray<AFHTTPSessionManager *> *)allManagers {
    NSMutableArray<NSString *> *managerKeys = [NSMutableArray new];
    [QueuesSingleton wmf_enumeratePropertiesUntilSuperclass:[NSObject class]
                                                 usingBlock:^(objc_property_t prop, BOOL *stop) {
                                                     NSString *name = [NSString stringWithCString:property_getName(prop) encoding:NSUTF8StringEncoding];
                                                     if ([name hasSuffix:@"Manager"]) {
                                                         [managerKeys addObject:name];
                                                     }
                                                 }];
    return [managerKeys wmf_map:^id(NSString *key) {
        return [[QueuesSingleton sharedInstance] valueForKey:key];
    }];
}

@end
