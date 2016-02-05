
#import "UIKit/UIKit.h"
#import "MWKSiteDataObject.h"

@class MWKTitle;
@class MWKArticle;
@class MWKImageInfo;

@interface MWKImage : MWKSiteDataObject

/**
 * Article the image was parsed from.
 */
@property (readonly, weak, nonatomic) MWKArticle* article;

/**
 * URL pointing to the receiver's data.
 */
@property (readonly, copy, nonatomic) NSURL* sourceURL;

/**
 * Absolute string of `sourceURL`.
 */
@property (readonly, copy, nonatomic) NSString* sourceURLString;

#pragma mark - Size

/**
 * Width of the receiver's image.
 * @warning This might be a guess based on the dimensions specified in the <img> tag the receiver was
 *          parsed from.
 */
@property (copy, nonatomic) NSNumber* width;

/**
 * Height of the receiver's image.
 * @warning This might be a guess based on the dimensions specified in the <img> tag the receiver was
 *          parsed from.
 */
@property (copy, nonatomic) NSNumber* height;

/**
 * @return CGSize with the receiver's `width` and `height`.
 */
- (CGSize)size;


/**
 * Local storage status
 */
@property (readonly, assign, nonatomic) BOOL isDownloaded;

#pragma mark - Initialization

/**
 * Initializes the image with the given `article` and `sourceURL`.
 */
- (instancetype)initWithArticle:(MWKArticle*)article sourceURL:(NSURL*)sourceURL NS_DESIGNATED_INITIALIZER;

/**
 * Convenience initializer, @see initWithArtile:sourceURL:
 */
- (instancetype)initWithArticle:(MWKArticle*)article sourceURLString:(NSString*)url;

#pragma mark - Serialization

/**
 * Initializes the receiver with the given article, and sets its properties with data from `dict`.
 * @param article  The article to associate this image with.
 * @param dict     A dictionary which contains data from a previous call to `-[MWKImage dataExport]`.
 */
- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict;

/**
 * Save the receiver in the same `MWKDataStore` as its `article`.
 */
- (void)save;


#pragma mark - Managing Face Information

- (BOOL)hasFaces;

- (BOOL)didDetectFaces;

/**
 * Array of NSValue-wrapped unit rectangles, in the coordinate space of the receiver's image (y-origin on the bottom).
 *
 * Used to cache the results of face detection.
 *
 * @see CIDetector+WMFFaceDetection
 */
@property (copy, nonatomic /*, nullable*/) NSArray<NSValue*>* allNormalizedFaceBounds;

/**
 * Convenience accessor for the bounds of the first face in `allNormalizedFaceBounds`.
 * @return The normalized bounds of the first face, or `CGRectZero` if allNormalizedFaceBounds is empty or `nil`.
 */
- (CGRect)firstFaceBounds;

#pragma mark - Variants

- (MWKImage*)largestVariant;
- (MWKImage*)largestCachedVariant;

- (MWKImage*)smallestVariant;
- (MWKImage*)smallestCachedVariant;


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

#pragma mark - File Properties

@property (readonly, copy, nonatomic) NSString* extension;
@property (readonly, copy, nonatomic) NSString* fileName;
@property (readonly, copy, nonatomic) NSString* fileNameNoSizePrefix;
@property (copy, nonatomic) NSString* mimeType;

/**
 * Return the folder containing the image file from receiver's @c sourceURL.
 */
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

/**
 * The name of the image "file" associatd with the receiver, with percent encodings replaced.
 */
+ (NSString*)canonicalFilenameFromSourceURL:(NSString*)sourceURL;

+ (NSInteger)fileSizePrefix:(NSString*)sourceURL;

#pragma mark - Comparison

- (BOOL)isEqualToImage:(MWKImage*)image;

- (BOOL)isLeadImage;

+ (CGSize)minimumImageSizeForGalleryInclusion;

@end

#pragma mark - Deprecated Methods

@interface MWKImage ()

- (void)importImageData:(NSData*)data WMF_TECH_DEBT_DEPRECATED;
- (void)updateWithData:(NSData*)data WMF_TECH_DEBT_DEPRECATED;

- (UIImage*)asUIImage WMF_TECH_DEBT_DEPRECATED;
- (NSData*)asNSData WMF_TECH_DEBT_DEPRECATED;
- (NSString*)fullImageBinaryPath WMF_TECH_DEBT_DEPRECATED;

@end
