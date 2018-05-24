#import <WMF/NSURL+WMFQueryParameters.h>
#import <WMF/WMF-Swift.h>
#import <WMF/NSURLComponents+WMFLinkParsing.h>

@implementation NSURL (WMFQueryParameters)

- (nullable NSString *)wmf_valueForQueryKey:(NSString *)key {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    return [components wmf_valueForQueryItemNamed:key];
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

@end
