#import "MWKSearchResult.h"
#import "WMFArticle+Extensions.h"

@interface MWKSearchResult ()

@property (nonatomic, assign, readwrite) NSInteger articleID;

@property (nonatomic, assign, readwrite) NSInteger revID;

@property (nonatomic, copy, readwrite) NSString *displayTitle;

@property (nonatomic, copy, readwrite) NSString *wikidataDescription;

@property (nonatomic, copy, readwrite) NSString *extract;

@property (nonatomic, copy, readwrite) NSURL *thumbnailURL;

@property (nonatomic, copy, readwrite) NSNumber *index;

@property (nonatomic, copy, readwrite) NSNumber *titleNamespace;

@property (nonatomic, assign, readwrite) BOOL isDisambiguation;

@property (nonatomic, assign, readwrite) BOOL isList;

@property (nonatomic, copy, readwrite) CLLocation *location;

@end

@implementation MWKSearchResult

- (instancetype)initWithArticleID:(NSInteger)articleID
                            revID:(NSInteger)revID
                     displayTitle:(NSString *)displayTitle
              wikidataDescription:(NSString *)wikidataDescription
                          extract:(NSString *)extract
                     thumbnailURL:(NSURL *)thumbnailURL
                            index:(NSNumber *)index
                 isDisambiguation:(BOOL)isDisambiguation
                           isList:(BOOL)isList
                   titleNamespace:(NSNumber *)titleNamespace {
    self = [super init];
    if (self) {
        self.articleID = articleID;
        self.revID = revID;
        self.displayTitle = displayTitle;
        self.wikidataDescription = wikidataDescription;
        self.extract = extract;
        self.thumbnailURL = thumbnailURL;
        self.index = index;
        self.isDisambiguation = isDisambiguation;
        self.isList = isList;
        self.titleNamespace = titleNamespace;
    }
    return self;
}

#pragma mark - MTLJSONSerializing

+ (NSValueTransformer *)thumbnailURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSString *urlString,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            return [NSURL wmf_optionalURLWithString:urlString];
        }
        reverseBlock:^NSString *(NSURL *thumbnailURL,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            return [thumbnailURL absoluteString];
        }];
}

+ (NSValueTransformer *)wikidataDescriptionJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value, BOOL *success, NSError *__autoreleasing *error) {
        NSString *description = [value firstObject];
        return [description wmf_stringByCapitalizingFirstCharacter];
    }];
}

+ (MTLValueTransformer *)extractJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *extract, BOOL *success, NSError *__autoreleasing *error) {
        // HAX: sometimes the api gives us "..." for the extract, which is not useful and messes up how random
        // weights relative quality of the random titles it retrieves.
        if ([extract isEqualToString:@"..."]) {
            extract = nil;
        }

        return [extract wmf_summaryFromText];
    }];
}

+ (NSValueTransformer *)isDisambiguationJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^(NSDictionary *value, BOOL *success, NSError **error) {
            NSString *disambiguation = value[@"pageprops.disambiguation"];
            if (disambiguation) {
                return @YES;
            }
            // HAX: occasionally the search api doesn't report back "disambiguation" page term ( T121288 ),
            // so double-check wiki data description for "disambiguation page" string.
            NSArray *descriptions = value[@"terms.description"];
            return @(descriptions.count && [descriptions.firstObject containsString:@"disambiguation page"]);
        }];
}

+ (NSValueTransformer *)isListJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^(NSArray *value, BOOL *success, NSError **error) {
            // HAX: check wiki data description for "Wikimedia list article" string. Not perfect
            // and enwiki specific, but confirmed with max that without doing separate wikidata query, there's no way to tell if it's a list at the moment.
            return @(value.count && [value.firstObject containsString:@"Wikimedia list article"]);
        }];
}

+ (NSValueTransformer *)revIDJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^id(NSArray *value, BOOL *success, NSError **error) {
            return (value.count > 0 && value.firstObject[@"revid"]) ? value.firstObject[@"revid"] : @(0);
        }];
}

+ (NSValueTransformer *)locationJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value,
                                                                 BOOL *success,
                                                                 NSError *__autoreleasing *error) {
        NSDictionary *coords = [value firstObject];
        NSNumber *lat = coords[@"lat"];
        NSNumber *lon = coords[@"lon"];
        
        if (![lat isKindOfClass:[NSNumber class]] || ![lon isKindOfClass:[NSNumber class]]) {
            return nil;
        }
        
        return [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];
    }];
}

+ (NSValueTransformer *)geoTypeJSONTransformer {
    static NSDictionary *geoTypeLookup;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        geoTypeLookup = @{@"country":@(WMFGeoTypeCountry),
                          @"satellite":@(WMFGeoTypeSatellite),
                          @"adm1st":@(WMFGeoTypeAdm1st),
                          @"adm2nd":@(WMFGeoTypeAdm2nd),
                          @"adm3rd":@(WMFGeoTypeAdm3rd),
                          @"city":@(WMFGeoTypeCity),
                          @"airport":@(WMFGeoTypeAirport),
                          @"mountain":@(WMFGeoTypeMountain),
                          @"isle":@(WMFGeoTypeIsle),
                          @"waterbody":@(WMFGeoTypeWaterBody),
                          @"forest":@(WMFGeoTypeForest),
                          @"river":@(WMFGeoTypeRiver),
                          @"glacier":@(WMFGeoTypeGlacier),
                          @"event":@(WMFGeoTypeEvent),
                          @"edu":@(WMFGeoTypeEdu),
                          @"pass":@(WMFGeoTypePass),
                          @"railwaystation":@(WMFGeoTypeRailwayStation),
                          @"landmark":@(WMFGeoTypeLandmark)};
    });
    
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value,
                                                                 BOOL *success,
                                                                 NSError *__autoreleasing *error) {
        NSDictionary *coords = [value firstObject];
        NSString *type = coords[@"type"];
        
        if (![type isKindOfClass:[NSString class]]) {
            return nil;
        }
        
        type = [type lowercaseString];
        
        if ([type hasPrefix:@"city"]) {
            type = @"city";
        }
        
        return geoTypeLookup[type];
    }];
}

+ (NSValueTransformer *)geoDimensionJSONTransformer {
    static dispatch_once_t onceToken;
    static NSCharacterSet *nonNumericCharacterSet;
    dispatch_once(&onceToken, ^{
        nonNumericCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    });
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value,
                                                                 BOOL *success,
                                                                 NSError *__autoreleasing *error) {
        NSDictionary *coords = [value firstObject];
        NSString *dim = coords[@"dim"];
        
        if (![dim isKindOfClass:[NSString class]]) {
            return nil;
        }
        
        NSString *dimToParse = [dim stringByTrimmingCharactersInSet:nonNumericCharacterSet];
        long long dimension = [dimToParse longLongValue];
        if (dimension == 0) {
            return nil;
        }
        
        dim = [dim lowercaseString];
        if ([dim hasSuffix:@"km"]) {
            dimension = dimension * 1000;
        }
        
        return @(dimension);
    }];
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(MWKSearchResult.new, displayTitle): @"title",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, articleID): @"pageid",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, revID): @"revisions",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, thumbnailURL): @"thumbnail.source",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, wikidataDescription): @"terms.description",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, extract): @"extract",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, index): @"index",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, isDisambiguation): @[@"pageprops.disambiguation", @"terms.description"],
              WMF_SAFE_KEYPATH(MWKSearchResult.new, isList): @"terms.description",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, location): @"coordinates",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, geoDimension): @"coordinates",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, geoType): @"coordinates",
              WMF_SAFE_KEYPATH(MWKSearchResult.new, titleNamespace): @"ns" };
}

@end
