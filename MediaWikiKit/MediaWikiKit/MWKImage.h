//
//  MWKImage.h
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "MWKSiteDataObject.h"

@class MWKTitle;
@class MWKArticle;
@class MWKImageInfo;

@interface MWKImage : MWKSiteDataObject

// Identifiers
@property (readonly) MWKSite* site;
@property (readonly) MWKArticle* article;

// Metadata, static
@property (readonly) NSString* sourceURL;
@property (readonly) NSString* extension;
@property (readonly) NSString* fileName;
@property (readonly) NSString* fileNameNoSizePrefix;

// Metadata, variable
@property (copy) NSDate* dateLastAccessed;
@property (copy) NSDate* dateRetrieved;
@property (copy) NSString* mimeType;
@property (copy) NSNumber* width;
@property (copy) NSNumber* height;

// Local storage status
@property (readonly) BOOL isCached;

- (instancetype)initWithArticle:(MWKArticle*)article sourceURL:(NSString*)url;
- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict;

- (void)importImageData:(NSData*)data;

- (BOOL)isEqualToImage:(MWKImage*)image;

// internal
- (void)updateWithData:(NSData*)data;
- (void)updateLastAccessed;
- (void)save;

- (UIImage*)asUIImage;
- (NSData*) asNSData;

- (MWKImage*)largestVariant;
- (MWKImage*)largestCachedVariant;

/// Return the folder containing the image file from receiver's @c sourceURL.
- (NSString*)basename;

/**
 * The receiver's canonical filename, after normalization.
 * @see -canonicalFilenameFromSourceURL
 * @see WMFNormalizedPageTitle()
 */
- (NSString*)canonicalFilename;

/**
 * The receiver's canonical filename, with any present percent encodings and underscores.
 * @see +canonicalFilenameFromSourceURL:
 */
- (NSString*)canonicalFilenameFromSourceURL;

/**
 * The name of the image "file" associatd with @c sourceURL (without the XXXpx prefix).
 * @param sourceURL A @c NSURL pointing to an image file in the format @c "//site/.../Filename.jpg[/XXXpx-Filename.jpg".
 * @note This method returns the filename <b>with</b> percent encodings.
 */
+ (NSString*)fileNameNoSizePrefix:(NSString*)sourceURL;

/// The name of the image "file" associatd with the receiver, with percent encodings replaced.
+ (NSString*)canonicalFilenameFromSourceURL:(NSString*)sourceURL;

+ (NSInteger)fileSizePrefix:(NSString*)sourceURL;

/**
 * Checks if two images are variants of each other <b>but not exactly the same image</b>.
 * @discussion For example: <br/>
   @code
   MWKImage *img; // sourceURL = .../foo.jpg/440px-foo.jpg
   MWKImage *imgAtOtherRes; // sourceURL = .../foo.jpg/7200px-foo.jpg
   MWKImage *otherImage; // sourceURL = .../bar.jpg/440px-bar.jpg
   [img isVariantOfImage:imgAtOtherRes]; //< returns YES
   [img isVariantOfImage:otherImage]; //< returns YES
   [img isVariantOfImage:img]; //< returns NO
   @endcode
 */
- (BOOL)isVariantOfImage:(MWKImage*)otherImage;

- (NSString*)fullImageBinaryPath;

@end
