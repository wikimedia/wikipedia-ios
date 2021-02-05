#import <WMF/MWKImageInfoFetcher.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/UIScreen+WMFImageWidth.h>
#import <WMF/WMF-Swift.h>

/// Required extmetadata keys, don't forget to add new ones to +requiredExtMetadataKeys!
static NSString *const ExtMetadataImageDescriptionKey = @"ImageDescription";
static NSString *const ExtMetadataArtistKey = @"Artist";
static NSString *const ExtMetadataLicenseUrlKey = @"LicenseUrl";
static NSString *const ExtMetadataLicenseShortNameKey = @"LicenseShortName";
static NSString *const ExtMetadataLicenseKey = @"License";

static CGSize MWKImageInfoSizeFromJSON(NSDictionary *json, NSString *widthKey, NSString *heightKey) {
    NSNumber *width = json[widthKey];
    NSNumber *height = json[heightKey];
    if (width && height) {
        // both NSNumber & NSString respond to `floatValue`
        return CGSizeMake([width floatValue], [height floatValue]);
    } else {
        return CGSizeZero;
    }
}

@implementation MWKImageInfoFetcher

- (id)initWithDataStore:(MWKDataStore *)dataStore {
    self = [super initWithSession:dataStore.session configuration:dataStore.configuration];
    if (self) {
        self.preferredLanguageDelegate = dataStore.languageLinkController;
    }
    return self;
}

- (void)fetchGalleryInfoForImage:(NSString *)canonicalPageTitle fromSiteURL:(NSURL *)siteURL failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    [self fetchGalleryInfoForImageFiles:@[canonicalPageTitle]
                            fromSiteURL:siteURL
                                success:^(NSArray *infoObjects) {
                                    success(infoObjects.firstObject);
                                }
                                failure:failure];
}

- (void)fetchGalleryInfoForImagesOnPages:(NSArray *)pageTitles
                             fromSiteURL:(NSURL *)siteURL
                        metadataLanguage:(NSString *)metadataLanguage
                                 failure:(WMFErrorHandler)failure
                                 success:(WMFSuccessIdHandler)success {
    [self fetchInfoForTitles:pageTitles
                 fromSiteURL:siteURL
              thumbnailWidth:[NSNumber numberWithInteger:[[UIScreen mainScreen] wmf_articleImageWidthForScale]]
             extmetadataKeys:[MWKImageInfoFetcher galleryExtMetadataKeys]
            metadataLanguage:metadataLanguage
                useGenerator:YES
                     success:success
                     failure:failure];
}

- (id<MWKImageInfoRequest>)fetchGalleryInfoForImageFiles:(NSArray *)imageTitles
                                             fromSiteURL:(NSURL *)siteURL
                                                 success:(void (^)(NSArray *infoObjects))success
                                                 failure:(void (^)(NSError *error))failure {
    return [self fetchInfoForTitles:imageTitles
                        fromSiteURL:siteURL
                     thumbnailWidth:[NSNumber numberWithInteger:[[UIScreen mainScreen] wmf_articleImageWidthForScale]]
                    extmetadataKeys:[MWKImageInfoFetcher galleryExtMetadataKeys]
                   metadataLanguage:siteURL.wmf_language
                       useGenerator:NO
                            success:success
                            failure:failure];
}

+ (NSArray *)galleryExtMetadataKeys {
    return @[ExtMetadataLicenseKey,
             ExtMetadataLicenseUrlKey,
             ExtMetadataLicenseShortNameKey,
             ExtMetadataImageDescriptionKey,
             ExtMetadataArtistKey];
}

- (id)responseObjectForJSON:(NSDictionary *)json preferredLanguageCodes:(NSArray<NSString *> *)preferredLanguageCodes error:(NSError *__autoreleasing *)error {
    if (!json) {
        if (error) {
            *error = [WMFFetcher invalidParametersError];
        }
        return nil;
    }
    NSDictionary *indexedImages = json[@"query"][@"pages"];
    
    if (!indexedImages) {
        return @[];
    }
    
    NSMutableArray *itemListBuilder = [NSMutableArray arrayWithCapacity:[[indexedImages allKeys] count]];

    [indexedImages enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *image, BOOL *stop) {
        NSDictionary *imageInfo = [image[@"imageinfo"] firstObject];
        NSDictionary *extMetadata = imageInfo[@"extmetadata"];
        // !!!: workaround for a nasty bug in JSON serialization in the back-end
        if (![extMetadata isKindOfClass:[NSDictionary class]]) {
            extMetadata = nil;
        }
        MWKLicense *license =
            [[MWKLicense alloc] initWithCode:extMetadata[ExtMetadataLicenseKey][@"value"]
                            shortDescription:extMetadata[ExtMetadataLicenseShortNameKey][@"value"]
                                         URL:[NSURL wmf_optionalURLWithString:extMetadata[ExtMetadataLicenseUrlKey][@"value"]]];

        NSString *description = nil;
        BOOL descriptionIsRTL = NO;
        NSString *descriptionLangCode = nil;

        id imageDescriptionValue = extMetadata[ExtMetadataImageDescriptionKey][@"value"];
        if ([imageDescriptionValue isKindOfClass:[NSDictionary class]]) {
            NSDictionary *availableDescriptionsByLangCode = imageDescriptionValue;
            descriptionLangCode = [self descriptionLangCodeToUseFromAvailableDescriptionsByLangCode:availableDescriptionsByLangCode forPreferredLangCodes:preferredLanguageCodes];
            if (descriptionLangCode) {
                description = availableDescriptionsByLangCode[descriptionLangCode];
                descriptionIsRTL = [MWKLanguageLinkController isLanguageRTLForContentLanguageCode:descriptionLangCode];
            }
        } else if ([imageDescriptionValue isKindOfClass:[NSString class]]) {
            description = imageDescriptionValue;
        }

        NSString *artist = nil;
        id artistValue = extMetadata[ExtMetadataArtistKey][@"value"];
        if ([artistValue isKindOfClass:[NSDictionary class]]) {
            artist = artistValue[descriptionLangCode];
        } else if ([artistValue isKindOfClass:[NSString class]]) {
            artist = artistValue;
        }

        MWKImageInfo *item =
            [[MWKImageInfo alloc]
                initWithCanonicalPageTitle:image[@"title"]
                          canonicalFileURL:[NSURL wmf_optionalURLWithString:imageInfo[@"url"]]
                          imageDescription:[[description wmf_stringByRemovingHTML] wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation]
                     imageDescriptionIsRTL:descriptionIsRTL
                                   license:license
                               filePageURL:[NSURL wmf_optionalURLWithString:imageInfo[@"descriptionurl"]]
                             imageThumbURL:[NSURL wmf_optionalURLWithString:imageInfo[@"thumburl"]]
                                     owner:[[artist wmf_stringByRemovingHTML] wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation]
                                 imageSize:MWKImageInfoSizeFromJSON(imageInfo, @"width", @"height")
                                 thumbSize:MWKImageInfoSizeFromJSON(imageInfo, @"thumbwidth", @"thumbheight")];
        [itemListBuilder addObject:item];
    }];
    return itemListBuilder;
}

- (NSString *)descriptionLangCodeToUseFromAvailableDescriptionsByLangCode:(NSDictionary *)availableDescriptionsByLangCode forPreferredLangCodes:(NSArray<NSString *> *)preferredLangCodes {
    // use first of user's preferred lang codes for which we have a translation
    for (NSString *langCode in preferredLangCodes) {
        if ([availableDescriptionsByLangCode objectForKey:langCode]) {
            return langCode;
        }
    }
    // else use "en" description if available
    if ([availableDescriptionsByLangCode objectForKey:@"en"]) {
        return @"en";
    }
    // else use first description lang code
    for (NSString *langCode in availableDescriptionsByLangCode.allKeys) {
        if (![langCode hasPrefix:@"_"]) { // there's a weird "_type" key in the results for some reason
            return langCode;
        }
    }
    // else no luck
    return nil;
}

- (nullable NSURL *)galleryInfoURLForImageTitles: (NSArray *)imageTitles
                            fromSiteURL: (NSURL *)siteURL {
    
    NSDictionary *params = [self queryParametersForTitles:imageTitles fromSiteURL:siteURL thumbnailWidth:[NSNumber numberWithInteger:[[UIScreen mainScreen] wmf_articleImageWidthForScale]] extmetadataKeys:[MWKImageInfoFetcher galleryExtMetadataKeys] metadataLanguage:siteURL.wmf_language useGenerator:NO];
    
    if (siteURL.host) {
        return [self.configuration mediaWikiAPIURLForURL:siteURL withQueryParameters:params];
    }
    
    return nil;
}

- (NSDictionary *)queryParametersForTitles:(NSArray *)titles
     fromSiteURL:(NSURL *)siteURL
  thumbnailWidth:(NSNumber *)thumbnailWidth
 extmetadataKeys:(NSArray<NSString *> *)extMetadataKeys
metadataLanguage:(nullable NSString *)metadataLanguage
                              useGenerator:(BOOL)useGenerator {
    if (!titles) {
        return @{};
    }

    NSMutableDictionary *params =
        [@{@"format": @"json",
           @"action": @"query",
           @"titles": [titles componentsJoinedByString:@"|"],
           // suppress continue warning
           @"rawcontinue": @"",
           @"prop": @"imageinfo",
           @"iiprop": [@[@"url", @"extmetadata", @"dimensions"] componentsJoinedByString:@"|"],
           @"iiextmetadatafilter": [extMetadataKeys ?: @[] componentsJoinedByString:@"|"],
           @"iiextmetadatamultilang": @1,
           @"iiurlwidth": thumbnailWidth} mutableCopy];

    if (useGenerator) {
        params[@"generator"] = @"images";
    }

    if (metadataLanguage) {
        params[@"iiextmetadatalanguage"] = metadataLanguage;
    }
    
    return [params copy];
}

- (nullable NSURLRequest *)urlRequestForFromURL: (NSURL *)url {
    
    return [self.session imageInfoURLRequestFromPersistenceWith: url];
}

- (id<MWKImageInfoRequest>)fetchInfoForTitles:(NSArray *)titles
                                  fromSiteURL:(NSURL *)siteURL
                               thumbnailWidth:(NSNumber *)thumbnailWidth
                              extmetadataKeys:(NSArray<NSString *> *)extMetadataKeys
                             metadataLanguage:(nullable NSString *)metadataLanguage
                                 useGenerator:(BOOL)useGenerator
                                      success:(void (^)(NSArray *))success
                                      failure:(void (^)(NSError *))failure {
    NSParameterAssert([titles count]);
    NSAssert([titles count] <= 50, @"Only 50 titles can be queried at a time.");
    NSParameterAssert(siteURL);

    NSDictionary *params = [self queryParametersForTitles:titles fromSiteURL:siteURL thumbnailWidth:thumbnailWidth extmetadataKeys:extMetadataKeys metadataLanguage:metadataLanguage useGenerator:useGenerator];
    
    NSURL *url = [self.fetcher.configuration mediaWikiAPIURLForURL:siteURL withQueryParameters:params];

    NSURLRequest *urlRequest = [self urlRequestForFromURL:url];
    
    return (id<MWKImageInfoRequest>)[self performMediaWikiAPIGETForURLRequest:urlRequest completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            failure(error);
            return;
        }
        [self getPreferredLanguageCodes:^(NSArray<NSString *> *preferredLanguageCodes) {
            NSError *serializerError = nil;
            NSArray *galleryItems = [self responseObjectForJSON:result preferredLanguageCodes:preferredLanguageCodes error:&serializerError];
            if (serializerError) {
                failure(serializerError);
                return;
            }
            success(galleryItems);
        }];
    }];
}

- (void)getPreferredLanguageCodes:(void (^)(NSArray<NSString *> *))completion {
    if (!self.preferredLanguageDelegate) {
        NSAssert(false, @"Preferred language delegate should be set");
        completion(@[@"en"]);
        return;
    }
    [self.preferredLanguageDelegate getPreferredLanguageCodes:completion];
}

- (void)fetchImageInfoForCommonsFiles:(NSArray *)filenames
                                failure:(WMFErrorHandler)failure
                                success:(WMFSuccessIdHandler)success {
    NSURL *commonsURL = [self.configuration commonsAPIURLComponentsWithQueryParameters:nil].URL;
    [self fetchGalleryInfoForImageFiles:filenames fromSiteURL:commonsURL success:success failure:failure];
}

@end
