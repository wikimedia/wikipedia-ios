//
//  MWKImageMetadata.h
//  MediaWikiKit
//
//  Created by Brion on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"
#import "MWKLicense.h"

@interface MWKImageInfo : MWKDataObject

/// Name of the canonical file associated with this image, in the format @c "File:Some_file_name.extension".
@property (nonatomic, readonly, copy) NSString *canonicalPageTitle;

/// URL pointing at the canonical file associated with this gallery item, e.g. @c "//site/.../Some_file_name.extension".
@property (nonatomic, readonly) NSURL *canonicalFileURL;

/// Short description of the image contents (e.g. "John Smith posing for a picture").
@property (nonatomic, readonly, copy) NSString *imageDescription;

@property (nonatomic, readonly) MWKLicense *license;

/// URL pointing to the corresponding file page for the receiver.
@property (nonatomic, readonly) NSURL *filePageURL;

/// URL pointing at the original image (at the uploaded resolution).
@property (nonatomic, readonly) NSURL *imageURL;

/// URL pointing at a thumbnail version of the image at @c imageURL.
@property (nonatomic, readonly) NSURL *imageThumbURL;

/// Name of the entity owning this image.
@property (nonatomic, readonly, copy) NSString *owner;

/// Factory method for creating an instance from the output of @c exportData.
+ (instancetype)imageInfoWithExportedData:(NSDictionary*)exportedData;

- (instancetype)initWithCanonicalPageTitle:(NSString*)canonicalPageTitle
                          canonicalFileURL:(NSURL*)canonicalFileURL
                          imageDescription:(NSString*)imageDescription
                                   license:(MWKLicense*)license
                               filePageURL:(NSURL*)filePageURL
                                  imageURL:(NSURL*)imageURL
                             imageThumbURL:(NSURL*)imageThumbURL
                                     owner:(NSString*)owner;

/// Name of the canonical file associated with the receiver, without the "File:" prefix.
- (NSString*)canonicalFilename;

@end
