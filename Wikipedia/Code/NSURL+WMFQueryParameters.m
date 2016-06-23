//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURL+WMFQueryParameters.h"

@implementation NSURL (WMFQueryParameters)

- (nullable NSString*)wmf_valueForQueryKey:(NSString*)key {
    NSURLQueryItem* matchingItem = [[[NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES] queryItems]
                                 bk_match:^BOOL (NSURLQueryItem* item) {
                                     return [item.name isEqualToString:key];
                                 }];
    return matchingItem.value;
}

- (NSURL*)wmf_urlWithValue:(NSString*)value forQueryKey:(NSString*)key {
    NSURLComponents* components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];

    if([self wmf_valueForQueryKey:key]){
        // Change the value if the key already exists.
        NSArray<NSURLQueryItem *> *queryItems = [components.queryItems
                                                 bk_map:^id (NSURLQueryItem* item) {
                                                     if ([item.name isEqualToString:key]) {
                                                         return [NSURLQueryItem queryItemWithName:item.name value:value];
                                                     }else{
                                                         return item;
                                                     }
                                                 }];
        components.queryItems = queryItems;
    }else{
        // The key didn't exist, so add the key/value pair.
        NSURLQueryItem *newItem = [[NSURLQueryItem alloc] initWithName:key value:value];
        if (newItem) {
            NSArray *newItemArray = @[newItem];
            if (components.queryItems) {
                components.queryItems = [components.queryItems arrayByAddingObjectsFromArray:newItemArray];
            }else{
                components.queryItems = newItemArray;
            }
        }
    }
    return components.URL;
}

@end
