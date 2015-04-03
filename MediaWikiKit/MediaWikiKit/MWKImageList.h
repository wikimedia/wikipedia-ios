//
//  MWKImageList.h
//  MediaWikiKit
//
//  Created by Brion on 12/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@class MWKArticle;
@class MWKSection;
@class MWKImage;

@interface MWKImageList : MWKSiteDataObject <NSFastEnumeration>
@property (weak, readonly) MWKArticle* article;
@property (weak, readonly) MWKSection* section;

- (instancetype)initWithArticle:(MWKArticle*)article section:(MWKSection*)section;
- (instancetype)initWithArticle:(MWKArticle*)article section:(MWKSection*)section dict:(NSDictionary*)dict;

- (NSUInteger)count;
- (NSString*) imageURLAtIndex:(NSUInteger)index;
- (MWKImage*)objectAtIndexedSubscript:(NSUInteger)index;

- (void)addImageURL:(NSString*)imageURL;

- (BOOL)hasImageURL:(NSString*)imageURL;

- (MWKImage*)imageWithURL:(NSString*)imageURL;

- (NSUInteger)indexOfImage:(MWKImage*)image;

- (BOOL)containsImage:(MWKImage*)image;

/**
 * Add @c imageURL to the receiver if not already present in its entries.
 * @return @YES if the URL was added, or @NO if it is already present.
 */
- (BOOL)addImageURLIfAbsent:(NSString*)imageURL;

/**
 * Return an array of known URLs for the same image that a URL has been given for,
 * ordered by pixel size (smallest to largest).
 *
 * May be an empty array if none known.
 */
- (NSArray*)imageSizeVariants:(NSString*)imageURL;

/**
 * Return the URL for the largest variant of image that actually has been saved
 * for the given image URL (may be larger or smaller than requested, or same).
 *
 * May be nil if none found.
 */
- (NSString*)largestImageVariant:(NSString*)image;
- (NSString*)smallestImageVariant:(NSString*)image;

/**
 * Searches the receiver for a cached image variant matching @c sourceURL.
 * @return An @c MWKImage object or @c nil if no matching variant is found.
 * @see -largestImageVariantForURL:cachedOnly:
 */
- (MWKImage*)largestImageVariantForURL:(NSString*)sourceURL;
- (MWKImage*)smallestImageVariantForURL:(NSString*)sourceURL;

/**
 * Find an image with the specified URL, optionally requiring it to be stored in the cache.
 * @param imageURL      The @c sourceURL of the image to be retrieved.
 * @param cachedOnly    Whether or not matches must also be cached.
 * @return A @c MWKImage object where @c sourceURL matches @c imageURL. If @c cachedOnly is @c YES, the object will also
 *         be cached. Otherwise @c nil if no matching, cached (if specified) entries are found.
 */
- (MWKImage*)largestImageVariantForURL:(NSString*)imageURL cachedOnly:(BOOL)cachedOnly;
- (MWKImage*)smallestImageVariantForURL:(NSString*)imageURL cachedOnly:(BOOL)cachedOnly;

/**
 * Reduce the receiver by removing all but the largest variants of the contained images, preserving order.
 * @warning In an effort to make this method more reliable, it should always return an image for each entry in the list,
 *          but some of the returned images might not be cached.
 * @return A non-empty array of @c MWKImage objects or @c nil if there are no uncached images.
 */
- (NSArray*)uniqueLargestVariants;

@property (readonly) BOOL dirty;

- (void)save;

@end
