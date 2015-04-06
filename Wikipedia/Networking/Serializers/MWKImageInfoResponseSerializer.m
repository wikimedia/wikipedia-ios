//
//  WMFImageMetadataSerializer.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfoResponseSerializer.h"
#import "WMFNetworkUtilities.h"
#import "MWKImageInfo.h"
#import "NSString+WMFHTMLParsing.h"

/// Required extmetadata keys, don't forget to add new ones to +requiredExtMetadataKeys!
static NSString* const ExtMetadataImageDescriptionKey = @"ImageDescription";
static NSString* const ExtMetadataArtistKey           = @"Artist";
static NSString* const ExtMetadataLicenseUrlKey       = @"LicenseUrl";
static NSString* const ExtMetadataLicenseShortNameKey = @"LicenseShortName";
static NSString* const ExtMetadataLicenseKey          = @"License";

static CGSize MWKImageInfoSizeFromJSON(NSDictionary* json, NSString* widthKey, NSString* heightKey) {
    NSNumber* width  = json[widthKey];
    NSNumber* height = json[heightKey];
    if (width && height) {
        // both NSNumber & NSString respond to `floatValue`
        return CGSizeMake([width floatValue], [height floatValue]);
    } else {
        return CGSizeZero;
    }
}

@implementation MWKImageInfoResponseSerializer

+ (NSArray*)requiredExtMetadataKeys {
    return @[ExtMetadataLicenseKey,
             ExtMetadataLicenseUrlKey,
             ExtMetadataLicenseShortNameKey,
             ExtMetadataImageDescriptionKey,
             ExtMetadataArtistKey];
}

- (id)responseObjectForResponse:(NSURLResponse*)response
                           data:(NSData*)data
                          error:(NSError* __autoreleasing*)error {
    NSDictionary* json = [super responseObjectForResponse:response data:data error:error];
    if (!json || *error) {
        return nil;
    }
    NSDictionary* apiError = json[@"error"];
    if (apiError) {
        if (error) {
            *error = WMFErrorForApiErrorObject(apiError);
        }
        return nil;
    }
    NSDictionary* indexedImages     = json[@"query"][@"pages"];
    NSMutableArray* itemListBuilder = [NSMutableArray arrayWithCapacity:[[indexedImages allKeys] count]];
    [indexedImages enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSDictionary* image, BOOL* stop) {
        NSDictionary* imageInfo = [image[@"imageinfo"] firstObject];
        NSDictionary* extMetadata = imageInfo[@"extmetadata"];
        // !!!: workaround for a nasty bug in JSON serialization in the back-end
        if (![extMetadata isKindOfClass:[NSDictionary class]]) {
            extMetadata = nil;
        }
        MWKLicense* license =
            [[MWKLicense alloc] initWithCode:extMetadata[ExtMetadataLicenseKey][@"value"]
                            shortDescription:extMetadata[ExtMetadataLicenseShortNameKey][@"value"]
                                         URL:[NSURL URLWithString:extMetadata[ExtMetadataLicenseUrlKey][@"value"]]];

        MWKImageInfo* item =
            [[MWKImageInfo alloc]
             initWithCanonicalPageTitle:image[@"title"]
                       canonicalFileURL:[NSURL URLWithString:imageInfo[@"url"]]
                       imageDescription:[[extMetadata[ExtMetadataImageDescriptionKey][@"value"] wmf_joinedHtmlTextNodes] wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation]
                                license:license
                            filePageURL:[NSURL URLWithString:imageInfo[@"descriptionurl"]]
                               imageURL:[NSURL URLWithString:imageInfo[@"url"]]
                          imageThumbURL:[NSURL URLWithString:imageInfo[@"thumburl"]]
                                  owner:[[extMetadata[ExtMetadataArtistKey][@"value"] wmf_joinedHtmlTextNodes] wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation]
                              imageSize:MWKImageInfoSizeFromJSON(imageInfo, @"width", @"height")
                              thumbSize:MWKImageInfoSizeFromJSON(imageInfo, @"thumbwidth", @"thumbheight")];
        [itemListBuilder addObject:item];
    }];
    return itemListBuilder;
}

@end
