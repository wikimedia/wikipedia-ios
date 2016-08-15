//
//  QueuesSingleton+AllManagers.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

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
    return [managerKeys bk_map:^id(NSString *key) {
      return [[QueuesSingleton sharedInstance] valueForKey:key];
    }];
}

@end
