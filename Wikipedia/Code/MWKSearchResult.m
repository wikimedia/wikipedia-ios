#import <WMF/MWKSearchResult.h>
#import <WMF/WMFArticle+Extensions.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/NSString+WMFHTMLParsing.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/NSString+WMFExtras.h>

@interface MWKSearchResult ()

@property (nonatomic, assign, readwrite) NSInteger articleID;

@property (nonatomic, assign, readwrite) NSInteger revID;

@property (nonatomic, copy, readwrite) NSString *title;

@property (nonatomic, copy, readwrite) NSString *displayTitle;

@property (nonatomic, copy, readwrite) NSString *displayTitleHTML;

@property (nonatomic, copy, readwrite) NSString *wikidataDescription;

@property (nonatomic, copy, readwrite) NSString *extract;

@property (nonatomic, copy, readwrite) NSURL *thumbnailURL;

@property (nonatomic, copy, readwrite) NSNumber *index;

@property (nonatomic, copy, readwrite) NSNumber *titleNamespace;

@property (nonatomic, copy, readwrite) CLLocation *location;

@end

@implementation MWKSearchResult

- (instancetype)initWithArticleID:(NSInteger)articleID
                            revID:(NSInteger)revID
                            title:(NSString *)title
                     displayTitle:(NSString *)displayTitle
                 displayTitleHTML:(NSString *)displayTitleHTML
              wikidataDescription:(NSString *)wikidataDescription
                          extract:(NSString *)extract
                     thumbnailURL:(NSURL *)thumbnailURL
                            index:(NSNumber *)index
                   titleNamespace:(NSNumber *)titleNamespace
                         location:(nullable CLLocation *)location {
    self = [super init];
    if (self) {
        self.articleID = articleID;
        self.revID = revID;
        self.title = title;
        self.displayTitle = displayTitle;
        self.displayTitleHTML = displayTitleHTML;
        self.wikidataDescription = wikidataDescription;
        self.extract = extract;
        self.thumbnailURL = thumbnailURL;
        self.index = index;
        self.titleNamespace = titleNamespace;
        self.location = location;
    }
    return self;
}

+ (NSUInteger)modelVersion {
    return 4;
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

+ (MTLValueTransformer *)extractJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *extract, BOOL *success, NSError *__autoreleasing *error) {
        // Remove trailing ellipsis added by the API
        if ([extract hasSuffix:@"..."]) {
            if (extract.length == 3) {
                // HAX: sometimes the api gives us "..." for the extract, which is not useful and messes up how random
                // weights relative quality of the random titles it retrieves.
                extract = nil;
            } else {
                extract = [extract substringWithRange:NSMakeRange(0, extract.length - 3)];
            }
        }

        return [extract wmf_summaryFromText];
    }];
}

+ (NSString *)displayTitleFromValue:(NSDictionary *)value {
    NSString *displayTitle = value[@"pageprops.displaytitle"];
    if ([displayTitle isKindOfClass:[NSString class]]) { // nil & type check just to be safe
        return displayTitle;
    }
    NSString *title = value[@"title"];
    if ([title isKindOfClass:[NSString class]]) { // nil & type check just to be safe
        return title;
    }
    return @"";
}

+ (NSValueTransformer *)displayTitleJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^(NSDictionary *value, BOOL *success, NSError **error) {
            return [[self displayTitleFromValue:value] wmf_stringByRemovingHTML];
        }];
}

+ (NSValueTransformer *)displayTitleHTMLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^(NSDictionary *value, BOOL *success, NSError **error) {
            return [self displayTitleFromValue:value];
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
        geoTypeLookup = @{@"country": @(WMFGeoTypeCountry),
                          @"satellite": @(WMFGeoTypeSatellite),
                          @"adm1st": @(WMFGeoTypeAdm1st),
                          @"adm2nd": @(WMFGeoTypeAdm2nd),
                          @"adm3rd": @(WMFGeoTypeAdm3rd),
                          @"city": @(WMFGeoTypeCity),
                          @"airport": @(WMFGeoTypeAirport),
                          @"mountain": @(WMFGeoTypeMountain),
                          @"isle": @(WMFGeoTypeIsle),
                          @"waterbody": @(WMFGeoTypeWaterBody),
                          @"forest": @(WMFGeoTypeForest),
                          @"river": @(WMFGeoTypeRiver),
                          @"glacier": @(WMFGeoTypeGlacier),
                          @"event": @(WMFGeoTypeEvent),
                          @"edu": @(WMFGeoTypeEdu),
                          @"pass": @(WMFGeoTypePass),
                          @"railwaystation": @(WMFGeoTypeRailwayStation),
                          @"landmark": @(WMFGeoTypeLandmark)};
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
    return @{WMF_SAFE_KEYPATH(MWKSearchResult.new, title): @"title",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, displayTitle): @[@"pageprops.displaytitle", @"title"],
             WMF_SAFE_KEYPATH(MWKSearchResult.new, displayTitleHTML): @[@"pageprops.displaytitle", @"title"],
             WMF_SAFE_KEYPATH(MWKSearchResult.new, articleID): @"pageid",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, revID): @"revisions",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, thumbnailURL): @"thumbnail.source",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, wikidataDescription): @"description",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, extract): @"extract",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, index): @"index",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, location): @"coordinates",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, geoDimension): @"coordinates",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, geoType): @"coordinates",
             WMF_SAFE_KEYPATH(MWKSearchResult.new, titleNamespace): @"ns"};
}

- (nullable NSURL *)articleURLForSiteURL:(nullable NSURL *)siteURL {
    if (siteURL == nil) {
        return nil;
    }
    if (self.title == nil) {
        return nil;
    }
    return [siteURL wmf_URLWithTitle:self.title];
}

- (NSString *)displayTitleHTML {
    return _displayTitleHTML && ![_displayTitleHTML isEqualToString:@""] ? _displayTitleHTML : _displayTitle;
}

#pragma mark - Propagate Language Variant Code

// No languageVariantCodePropagationSubelementKeys

+ (NSArray<NSString *> *)languageVariantCodePropagationURLKeys {
    return @[@"thumbnailURL"];
}

@end
