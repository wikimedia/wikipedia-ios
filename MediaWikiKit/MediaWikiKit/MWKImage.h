
#import "UIKit/UIKit.h"
#import "MWKSiteDataObject.h"

@class MWKTitle;
@class MWKArticle;
@class MWKImageInfo;

@interface MWKImage : MWKSiteDataObject

// Identifiers
@property (readonly, weak, nonatomic) MWKArticle* article;

// Metadata, static
@property (readonly, copy, nonatomic) NSString* sourceURL;
@property (readonly, copy, nonatomic) NSString* extension;
@property (readonly, copy, nonatomic) NSString* fileName;
@property (readonly, copy, nonatomic) NSString* fileNameNoSizePrefix;

// Metadata, variable
@property (copy, nonatomic) NSDate* dateLastAccessed;
@property (copy, nonatomic) NSDate* dateRetrieved;
@property (copy, nonatomic) NSString* mimeType;

@property (copy, nonatomic) NSNumber* width;
@property (copy, nonatomic) NSNumber* height;
- (CGSize)size;


// Local storage status
@property (readonly, assign, nonatomic) BOOL isCached;

- (instancetype)initWithArticle:(MWKArticle*)article sourceURL:(NSString*)url;
- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict;

/**
 *  Calculate focal rects
 *
 *  @param imageData optional, if you do not pass it the image data will be extracted from disk
 */
- (void)calculateFocalRectsBasedOnFaceDetectionWithImageData:(NSData*)imageData;

/**
 *  All focal rects as strings. Calculated via "calculateFocalRectsBasedOnFaceDetectionWithImageData"
 * Normally you do not need to access this directly, instead use the methods
 */
@property (readonly, copy, nonatomic) NSArray* focalRectsInUnitCoordinatesAsStrings;

/**
 *  Returns the primary focal rect
 *  If normalized is set to YES, the rect will be normailzed
 *  to the image size. If set to NO, the rect will be in
 *  terms of the unit rect coordinates (0…1)
 *
 *  @param normalized  Set YES to normalize to the image
 *  @return The primary focal rect
 */
- (CGRect)primaryFocalRectNormalizedToImageSize:(BOOL)normalized;

/**
 *  Returns a rect enclosing all focal rects
 *  If normalized is set to YES, the rect will be normailzed
 *  to the image size. If set to NO, the rect will be in
 *  terms of the unit rect coordinates (0…1)

 *  @return The rect enclosing all focal rects
 */
- (CGRect)rectEnclosingAllFocalRectsNormalizedToImageSize:(BOOL)normalized;


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

- (MWKImage*)smallestVariant;
- (MWKImage*)smallestCachedVariant;

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

- (BOOL)isLeadImage;

@end
