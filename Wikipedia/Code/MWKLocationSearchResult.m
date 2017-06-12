#import <WMF/MWKLocationSearchResult.h>
#import <WMF/WMFComparison.h>

@implementation MWKLocationSearchResult

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
        WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates): @"coordinates",
    }];

    return mapping;
}

@end
