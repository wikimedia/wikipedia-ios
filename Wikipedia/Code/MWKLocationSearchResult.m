#import "MWKLocationSearchResult.h"

@implementation MWKLocationSearchResult

+ (NSValueTransformer *)locationJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value,
                                                                 BOOL *success,
                                                                 NSError *__autoreleasing *error) {
        NSDictionary *coords = [value firstObject];
        NSNumber *lat = coords[@"lat"];
        NSNumber *lon = coords[@"lon"];

        if (![lat isKindOfClass:[NSNumber class]] || ![lon isKindOfClass:[NSNumber class]]) {
            WMFSafeAssign(success, NO);
            return nil;
        }

        return [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];
    }];
}

+ (NSValueTransformer *)distanceFromQueryCoordinatesJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value,
                                                                 BOOL *success,
                                                                 NSError *__autoreleasing *error) {
        NSDictionary *coords = [value firstObject];
        NSNumber *distance = coords[@"dist"];
        if (![distance isKindOfClass:[NSNumber class]]) {
            distance = @(0);
        }
        return distance;
    }];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    NSMutableDictionary *mapping = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    /*
       coordinates is an array of objects which have lat, lon, & dist fields. pick the fist one and set the corresponding
       properties here.
     */
    [mapping addEntriesFromDictionary:@{
        WMF_SAFE_KEYPATH([MWKLocationSearchResult new], location): @"coordinates",
        WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates): @"coordinates",
    }];

    return mapping;
}

@end
