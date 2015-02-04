// //  MWKImageMetadata.m
//  MediaWikiKit
//
//  Created by Brion on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "NSMutableDictionary+WMFMaybeSet.h"
#import "WikipediaAppUtils.h"

// !!!: don't change key constants w/o writing conversion code to pull values from the old keys

// Model Version 1.0.0
NSString* const mWKImageInfoModelVersionKey = @"modelVersion";
NSUInteger const MWKImageInfoModelVersion_1 = 1;

NSString* const MWKImageInfoCanonicalPageTitleKey = @"canonicalPageTitle";
NSString* const MWKImageInfoCanonicalFileURLKey = @"canonicalFileURL";
NSString* const MWKImageInfoImageDescriptionKey = @"imageDescription";
NSString* const MWKImageInfoFilePageURLKey = @"filePageURL";
NSString* const MWKImageInfoImageURLKey = @"imageURL";
NSString* const MWKImageInfoImageThumbURLKey = @"imageThumbURL";
NSString* const MWKImageInfoOwnerKey = @"owner";
NSString* const MWKImageInfoLicenseKey = @"license";

@implementation MWKImageInfo

- (instancetype)initWithCanonicalPageTitle:(NSString *)canonicalPageTitle
                          canonicalFileURL:(NSURL*)canonicalFileURL
                          imageDescription:(NSString*)imageDescription
                                   license:(MWKLicense*)license
                               filePageURL:(NSURL*)filePageURL
                                  imageURL:(NSURL*)imageURL
                             imageThumbURL:(NSURL*)imageThumbURL
                                     owner:(NSString*)owner
{
    // !!!: not sure what's guaranteed by the API
    //NSParameterAssert(canonicalPageTitle.length);
    //NSParameterAssert(canonicalFileURL.absoluteString.length);
    //NSParameterAssert([imageURL.absoluteString length]);
    self = [super init];
    if (self) {
        _canonicalPageTitle = [canonicalPageTitle copy];
        _imageDescription = [imageDescription copy];
        _owner = [owner copy];
        _license = license;
        _canonicalFileURL = canonicalFileURL;
        _filePageURL = filePageURL;
        _imageURL = imageURL;
        _imageThumbURL = imageThumbURL;
    }
    return self;
}

+ (instancetype)imageInfoWithExportedData:(NSDictionary*)exportedData
{
    // assume all model versions are 1.0.0
    return [[MWKImageInfo alloc]
            initWithCanonicalPageTitle:exportedData[MWKImageInfoCanonicalPageTitleKey]
            canonicalFileURL:[NSURL URLWithString:exportedData[MWKImageInfoCanonicalFileURLKey]]
            imageDescription:exportedData[MWKImageInfoImageDescriptionKey]
            license:[MWKLicense licenseWithExportedData:exportedData[MWKImageInfoLicenseKey]]
            filePageURL:[NSURL URLWithString:exportedData[MWKImageInfoFilePageURLKey]]
            imageURL:[NSURL URLWithString:exportedData[MWKImageInfoImageURLKey]]
            imageThumbURL:[NSURL URLWithString:exportedData[MWKImageInfoImageThumbURLKey]]
            owner:exportedData[MWKImageInfoOwnerKey]];
}

- (NSDictionary*)dataExport
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:6];

    dict[mWKImageInfoModelVersionKey]  = @(MWKImageInfoModelVersion_1);

    [dict wmf_maybeSetObject:self.canonicalPageTitle forKey:MWKImageInfoCanonicalPageTitleKey];
    [dict wmf_maybeSetObject:self.canonicalFileURL.absoluteString forKey:MWKImageInfoCanonicalFileURLKey];
    [dict wmf_maybeSetObject:self.imageDescription forKey:MWKImageInfoImageDescriptionKey];
    [dict wmf_maybeSetObject:self.filePageURL.absoluteString forKey:MWKImageInfoFilePageURLKey];
    [dict wmf_maybeSetObject:self.imageURL.absoluteString forKey:MWKImageInfoImageURLKey];
    [dict wmf_maybeSetObject:self.imageThumbURL.absoluteString forKey:MWKImageInfoImageThumbURLKey];
    [dict wmf_maybeSetObject:self.owner forKey:MWKImageInfoOwnerKey];

#warning TODO(bgerstle): only store the license "hash" or something and save the licenses separately
    [dict wmf_maybeSetObject:[self.license dataExport] forKey:MWKImageInfoLicenseKey];

    return [dict copy];
}

- (BOOL)isEqual:(id)obj
{
    if (obj == self) { return YES; }
    else if ([obj isKindOfClass:[MWKImageInfo class]]) { return [self isEqualToGalleryItem:obj]; }
    else { return NO; }
}

- (BOOL)isEqualToGalleryItem:(MWKImageInfo*)other
{
    return WMF_EQUAL(self.canonicalPageTitle, isEqualToString:, other.canonicalPageTitle)
            && WMF_IS_EQUAL(self.canonicalFileURL, other.canonicalFileURL)
            && WMF_EQUAL(self.imageDescription, isEqualToString:, other.imageDescription)
            && WMF_EQUAL(self.license, isEqualToLicense:, other.license)
            && WMF_IS_EQUAL(self.filePageURL, other.filePageURL)
            && WMF_IS_EQUAL(self.imageURL, other.imageURL)
            && WMF_IS_EQUAL(self.imageThumbURL, other.imageThumbURL)
            && WMF_EQUAL(self.owner, isEqualToString:, other.owner);
}

- (NSUInteger)hash
{
    return [self.canonicalPageTitle hash] ^ CircularBitwiseRotation([self.imageURL hash], 1);
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], self.canonicalPageTitle, self.imageURL];
}

#pragma mark - Calculated properties

- (NSString*)canonicalFilename
{
    if (self.canonicalPageTitle.length > 5) {
        // string after "File:" prefix
        return [self.canonicalPageTitle substringFromIndex:5];
    } else {
        return nil;
    }
}

@end
