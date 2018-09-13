#import <WMF/MWKSiteDataObject.h>
@import CoreGraphics;

@class MWKArticle;
@class MWKImageInfo;

@interface MWKImage : MWKSiteDataObject

/**
 * Article the image was parsed from.
 */
@property (readonly, weak, nonatomic) MWKArticle *article;

/**
 * URL pointing to the receiver's data.
 */
@property (readonly, copy, nonatomic) NSURL *sourceURL;

/**
 * Absolute string of `sourceURL`.
 */
@property (readonly, copy, nonatomic) NSString *sourceURLString;

#pragma mark - Size

/**
 * Width of the receiver's image.
 * @warning This might be a guess based on the dimensions specified in the <img> tag the receiver was
 *          parsed from.
 */
@property (copy, nonatomic) NSNumber *width;

/**
 * Height of the receiver's image.
 * @warning This might be a guess based on the dimensions specified in the <img> tag the receiver was
 *          parsed from.
 */
@property (copy, nonatomic) NSNumber *height;

/**
 * @return CGSize with the receiver's `width` and `height`.
 */
- (CGSize)size;

/**
 * Width of the original image file. For example, if this image is a thumbnail, this is the width of the original image.
 */
@property (copy, nonatomic) NSNumber *originalFileWidth;

/**
 * Height of the original image file. For example, if this image is a thumbnail, this is the height of the original image.
 */
@property (copy, nonatomic) NSNumber *originalFileHeight;

/**
 * @return CGSize with the receiver's original file `width` and `height`.
 */
@property (nonatomic, readonly) CGSize originalFileSize;
@property (nonatomic, readonly) BOOL hasOriginalFileSize;

#pragma mark - Initialization

/**
 * Initializes the image with the given `article` and `sourceURL`.
 */
- (instancetype)initWithArticle:(MWKArticle *)article sourceURL:(NSURL *)sourceURL NS_DESIGNATED_INITIALIZER;

/**
 * Convenience initializer, @see initWithArtile:sourceURL:
 */
- (instancetype)initWithArticle:(MWKArticle *)article sourceURLString:(NSString *)url;

- (instancetype)initWithURL:(NSURL *)url NS_UNAVAILABLE;

#pragma mark - Serialization

/**
 * Initializes the receiver with the given article, and sets its properties with data from `dict`.
 * @param article  The article to associate this image with.
 * @param dict     A dictionary which contains data from a previous call to `-[MWKImage dataExport]`.
 */
- (instancetype)initWithArticle:(MWKArticle *)article dict:(NSDictionary *)dict;

#pragma mark - Variants

/**
 * Checks if two images are variants of each other or the same image.
 * @discussion For example: <br/>
   @code
   MWKImage *img; // sourceURL = .../foo.jpg/440px-foo.jpg
   MWKImage *imgAtOtherRes; // sourceURL = .../foo.jpg/7200px-foo.jpg
   MWKImage *otherImage; // sourceURL = .../bar.jpg/440px-bar.jpg
   [img isVariantOfImage:imgAtOtherRes]; //< returns YES
   [img isVariantOfImage:otherImage]; //< returns NO
   [img isVariantOfImage:img]; //< returns YES
   @endcode
 */
- (BOOL)isVariantOfImage:(MWKImage *)otherImage;

#pragma mark - File Properties

@property (readonly, copy, nonatomic) NSString *extension;
@property (readonly, copy, nonatomic) NSString *fileName;
@property (readonly, copy, nonatomic) NSString *fileNameNoSizePrefix;
@property (copy, nonatomic) NSString *mimeType;

/**
 * Return the folder containing the image file from receiver's @c sourceURL.
 */
- (NSString *)basename;

/**
 * The receiver's canonical filename, after normalization.
 * @see -canonicalFilenameFromSourceURL
 * @see WMFNormalizedPageTitle()
 */
- (NSString *)canonicalFilename;

#pragma mark - Comparison

- (BOOL)isEqualToImage:(MWKImage *)image;

- (BOOL)isLeadImage;

@end
