
#import "MWKLocationSearchResult.h"

@implementation MWKLocationSearchResult

+ (NSValueTransformer*)locationJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        NSDictionary* coords = [value firstObject];
        NSNumber* lat = coords[@"lat"];
        NSNumber* lon = coords[@"lon"];

        if (!lat || !lon) {
            return nil;
        }

        return [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];
    }];
}

+ (NSValueTransformer*)distanceFromQueryCoordinatesJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        NSDictionary* coords = [value firstObject];
        NSNumber* distance = coords[@"dist"];
        return distance;
    }];
}


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    
    NSMutableDictionary* mapping = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    [mapping addEntriesFromDictionary: @{
                                         @"location": @"coordinates",
                                         @"distanceFromQueryCoordinates": @"coordinates",
                                         }];

    return mapping;
}

@end
