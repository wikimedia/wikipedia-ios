#import <Foundation/Foundation.h>
#import "OMGFormURLEncode.h"

static inline NSString *enc(id in, CFStringRef ignore) {
    return (__bridge_transfer  NSString *) CFURLCreateStringByAddingPercentEscapes(
        kCFAllocatorDefault,
        (__bridge CFStringRef)[in description],
        ignore,
        CFSTR(":/?&=;+!@#$()',*"),
        kCFStringEncodingUTF8);
}

#define enckey(in) enc(in, CFSTR("[]."))
#define encval(in) enc(in, NULL)

static NSArray *DoQueryMagic(NSString *key, id value) {
    NSMutableArray *parts = [NSMutableArray new];

    // Sort dictionary keys to ensure consistent ordering in query string,
    // which is important when deserializing potentially ambiguous sequences,
    // such as an array of dictionaries
    #define sortDescriptor [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)]

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[sortDescriptor]]) {
            id recursiveKey = key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey;
            [parts addObjectsFromArray:DoQueryMagic(recursiveKey, dictionary[nestedKey])];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        for (id nestedValue in value)
            [parts addObjectsFromArray:DoQueryMagic([NSString stringWithFormat:@"%@[]", key], nestedValue)];
    } else if ([value isKindOfClass:[NSSet class]]) {
        for (id obj in [value sortedArrayUsingDescriptors:@[sortDescriptor]])
            [parts addObjectsFromArray:DoQueryMagic(key, obj)];
    } else {
        [parts addObjectsFromArray:[NSArray arrayWithObjects:key, value, nil]];
    }

    return parts;

    #undef sortDescriptor
}

NSString *OMGFormURLEncode(NSDictionary *parameters) {
    if (parameters.count == 0)
        return @"";
    NSMutableString *queryString = [NSMutableString new];
    NSEnumerator *e = DoQueryMagic(nil, parameters).objectEnumerator;
    for (;;) {
        id const obj = e.nextObject;
        if (!obj) break;
        [queryString appendFormat:@"%@=%@&", enckey(obj), encval(e.nextObject)];
    }
    [queryString deleteCharactersInRange:NSMakeRange(queryString.length - 1, 1)];
    return queryString;
}
