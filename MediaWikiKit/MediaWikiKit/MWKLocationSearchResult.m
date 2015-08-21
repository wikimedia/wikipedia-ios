
#import "MWKLocationSearchResult.h"
#import "NSURL+Extras.h"
#import "NSString+Extras.h"

@implementation MWKLocationSearchResult

+ (NSValueTransformer*)thumbnailURLJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* value, BOOL* success, NSError* __autoreleasing* error) {
        return [NSURL wmf_optionalURLWithString:value];
    }];
}

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

+ (NSValueTransformer*)wikidataDescriptionJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSArray* value, BOOL* success, NSError* __autoreleasing* error) {
        NSString* description = [value firstObject];
        return [description wmf_stringByCapitalizingFirstCharacter];
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
    return @{
               @"displayTitle": @"title",
               @"articleID": @"pageid",
               @"thumbnailURL": @"thumbnail.source",
               @"location": @"coordinates",
               @"distanceFromQueryCoordinates": @"coordinates",
               @"wikidataDescription": @"terms.description"
    };
}

@end
