#import "MWKImageInfoResponseSerializer.h"
@import WMF;

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

@implementation MWKImageInfoResponseSerializer

+ (NSArray *)galleryExtMetadataKeys {
    return @[ExtMetadataLicenseKey,
             ExtMetadataLicenseUrlKey,
             ExtMetadataLicenseShortNameKey,
             ExtMetadataImageDescriptionKey,
             ExtMetadataArtistKey];
}

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error {
    NSDictionary *json = [super responseObjectForResponse:response data:data error:error];
    if (!json) {
        return nil;
    }
    NSDictionary *indexedImages = json[@"query"][@"pages"];
    NSMutableArray *itemListBuilder = [NSMutableArray arrayWithCapacity:[[indexedImages allKeys] count]];
    
    NSArray<NSString*>* preferredLangCodes = [[[MWKLanguageLinkController sharedInstance] preferredLanguages] wmf_map:^NSString*(MWKLanguageLink* language){
        return [language languageCode];
    }];
    
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
            descriptionLangCode = [self descriptionLangCodeToUseFromAvailableDescriptionsByLangCode:availableDescriptionsByLangCode forPreferredLangCodes:preferredLangCodes];
            if (descriptionLangCode) {
                description = availableDescriptionsByLangCode[descriptionLangCode];
                descriptionIsRTL = [[MWLanguageInfo rtlLanguages] containsObject:descriptionLangCode];
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
                          imageDescription:[[description wmf_joinedHtmlTextNodes] wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation]
                     imageDescriptionIsRTL:descriptionIsRTL
                                   license:license
                               filePageURL:[NSURL wmf_optionalURLWithString:imageInfo[@"descriptionurl"]]
                             imageThumbURL:[NSURL wmf_optionalURLWithString:imageInfo[@"thumburl"]]
                                     owner:[[artist wmf_joinedHtmlTextNodes] wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation]
                                 imageSize:MWKImageInfoSizeFromJSON(imageInfo, @"width", @"height")
                                 thumbSize:MWKImageInfoSizeFromJSON(imageInfo, @"thumbwidth", @"thumbheight")];
        [itemListBuilder addObject:item];
    }];
    return itemListBuilder;
}

- (NSString *)descriptionLangCodeToUseFromAvailableDescriptionsByLangCode:(NSDictionary *)availableDescriptionsByLangCode forPreferredLangCodes:(NSArray<NSString*>*) preferredLangCodes {
    // use first of user's preferred lang codes for which we have a translation
    for (NSString* langCode in preferredLangCodes) {
        if ([availableDescriptionsByLangCode objectForKey:langCode]) {
            return langCode;
        }
    }
    // else use "en" description if available
    if ([availableDescriptionsByLangCode objectForKey:@"en"]) {
        return @"en";
    }
    // else use first description lang code
    for (NSString* langCode in availableDescriptionsByLangCode.allKeys) {
        if (![langCode hasPrefix:@"_"]) { // there's a weird "_type" key in the results for some reason
            return langCode;
        }
    }
    // else no luck
    return nil;
}

@end
