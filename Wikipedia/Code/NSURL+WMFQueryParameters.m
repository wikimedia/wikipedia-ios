#import "NSURL+WMFQueryParameters.h"
#import <WMF/WMF-Swift.h>

@implementation NSURL (WMFQueryParameters)

- (nullable NSString *)wmf_valueForQueryKey:(NSString *)key {
    NSURLQueryItem *matchingItem = [[[NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES] queryItems]
        bk_match:^BOOL(NSURLQueryItem *item) {
            return [item.name isEqualToString:key];
        }];
    return matchingItem.value;
}

- (NSURL *)wmf_urlWithValue:(NSString *)value forQueryKey:(NSString *)key {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];

    if ([self wmf_valueForQueryKey:key]) {
        // Change the value if the key already exists.
        NSArray<NSURLQueryItem *> *queryItems = [components.queryItems
            wmf_map:^id(NSURLQueryItem *item) {
                if ([item.name isEqualToString:key]) {
                    return [NSURLQueryItem queryItemWithName:item.name value:value];
                } else {
                    return item;
                }
            }];
        components.queryItems = queryItems;
    } else {
        // The key didn't exist, so add the key/value pair.
        NSURLQueryItem *newItem = [[NSURLQueryItem alloc] initWithName:key value:value];
        if (newItem) {
            NSArray *newItemArray = @[newItem];
            if (components.queryItems) {
                components.queryItems = [components.queryItems arrayByAddingObjectsFromArray:newItemArray];
            } else {
                components.queryItems = newItemArray;
            }
        }
    }
    return components.URL;
}

- (NSURL *)wmf_urlWithoutQueryKey:(NSString *)key {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSArray<NSURLQueryItem *> *queryItems = [components.queryItems
        wmf_select:^BOOL(NSURLQueryItem *item) {
            return ([item.name isEqualToString:key]) ? NO : YES;
        }];
    components.queryItems = queryItems;
    return components.URL;
}

@end
