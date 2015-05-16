
#import "UIKit/UIKit.h"
#import "WikipediaAppUtils.h"
#import "MediaWikiKit.h"
#import "WMFImageURLParsing.h"
#import "WMFFaceDetector.h"
#import "WMFGeometry.h"
#import <BlocksKit/BlocksKit.h>

@interface MWKImage ()

// Identifiers
@property (readwrite, weak, nonatomic) MWKArticle* article;

// Metadata, static
@property (readwrite, copy, nonatomic) NSString* sourceURL;
@property (readwrite, copy, nonatomic) NSString* extension;
@property (readwrite, copy, nonatomic) NSString* fileName;
@property (readwrite, copy, nonatomic) NSString* fileNameNoSizePrefix;

@property (readwrite, assign, nonatomic) BOOL isCached;

@property (readwrite, copy, nonatomic) NSArray* focalRectsInUnitCoordinatesAsStrings;

@end

@implementation MWKImage

#pragma mark - Setup

- (instancetype)initWithArticle:(MWKArticle*)article sourceURL:(NSString*)url {
    self = [super initWithSite:article.site];
    if (self) {
        self.article = article;

        // fileNameNoSizePrefix is lazily derived from this property, so be careful if _sourceURL needs to be re-set
        self.sourceURL = url;

        self.focalRectsInUnitCoordinatesAsStrings = @[];
    }
    return self;
}

- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict {
    NSString* sourceURL = [self requiredString:@"sourceURL" dict:dict];
    self = [self initWithArticle:article sourceURL:sourceURL];
    if (self) {
        self.dateLastAccessed                     = [self optionalDate:@"dateLastAccessed" dict:dict];
        self.dateRetrieved                        = [self optionalDate:@"dateRetrieved" dict:dict];
        self.mimeType                             = [self optionalString:@"mimeType" dict:dict];
        self.width                                = [self optionalNumber:@"width" dict:dict];
        self.height                               = [self optionalNumber:@"height" dict:dict];
        self.focalRectsInUnitCoordinatesAsStrings = dict[@"focalRects"];
    }
    return self;
}

#pragma mark - Focal Rects

- (void)calculateFocalRectsBasedOnFaceDetectionWithImageData:(NSData*)imageData {
    if ([self.focalRectsInUnitCoordinatesAsStrings count] == 0) {
        if (!imageData) {
            imageData = [self asNSData];
        }

        static WMFFaceDetector* faceDetector = nil;
        if (!faceDetector) {
            faceDetector = [[WMFFaceDetector alloc] init];
        }
        [faceDetector setImageWithData:imageData];
        [faceDetector detectFaces];

        self.focalRectsInUnitCoordinatesAsStrings = [faceDetector allFaceBoundsAsStringsNormalizedToUnitRect];
    }
}

- (CGRect)normalizedRectFromRect:(CGRect)rect {
    CGRect imageRect = CGRectZero;
    imageRect.size = [self size];
    CGRect normalized = WMFRectWithUnitRectInReferenceRect(rect, imageRect);
    return normalized;
}

- (CGRect)primaryFocalRectNormalizedToImageSize:(BOOL)normalized {
    if (self.focalRectsInUnitCoordinatesAsStrings.count == 0) {
        return CGRectZero;
    }

    NSString* primary = [self.focalRectsInUnitCoordinatesAsStrings firstObject];
    CGRect rect       = CGRectFromString(primary);

    if (normalized) {
        rect = [self normalizedRectFromRect:rect];
    }

    return rect;
}

- (CGRect)rectEnclosingAllFocalRectsNormalizedToImageSize:(BOOL)normalized {
    __block CGRect enclosingRect = CGRectZero;

    [self.focalRectsInUnitCoordinatesAsStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        CGRect rect = CGRectFromString(obj);

        if (CGRectIsEmpty(enclosingRect)) {
            enclosingRect = rect;
        } else {
            enclosingRect = CGRectUnion(enclosingRect, rect);
        }
    }];

    if (normalized) {
        enclosingRect = [self normalizedRectFromRect:enclosingRect];
    }

    return enclosingRect;
}

#pragma mark - Accessors

- (CGSize)size {
    return CGSizeMake([self.width floatValue], [self.height floatValue]);
}

- (NSString*)extension {
    return [self.sourceURL pathExtension];
}

- (NSString*)fileName {
    return [self.sourceURL lastPathComponent];
}

- (NSString*)basename {
    NSArray* sourceURLComponents = [self.sourceURL componentsSeparatedByString:@"/"];
    NSParameterAssert(sourceURLComponents.count >= 2);
    return sourceURLComponents[sourceURLComponents.count - 2];
}

- (NSString*)canonicalFilename {
    return WMFNormalizedPageTitle([self canonicalFilenameFromSourceURL]);
}

- (NSString*)canonicalFilenameFromSourceURL {
    return [MWKImage canonicalFilenameFromSourceURL:self.sourceURL];
}

+ (NSString*)fileNameNoSizePrefix:(NSString*)sourceURL {
    return WMFParseImageNameFromSourceURL(sourceURL);
}

+ (NSString*)canonicalFilenameFromSourceURL:(NSString*)sourceURL {
    return [[self fileNameNoSizePrefix:sourceURL] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSInteger)fileSizePrefix:(NSString*)sourceURL {
    return WMFParseSizePrefixFromSourceURL(sourceURL);
}

- (NSString*)fileNameNoSizePrefix {
    if (!_fileNameNoSizePrefix) {
        _fileNameNoSizePrefix = [MWKImage fileNameNoSizePrefix:self.sourceURL];
    }
    return _fileNameNoSizePrefix;
}

#pragma mark - Import / Export

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict[@"sourceURL"] = self.sourceURL;
    if (self.dateLastAccessed) {
        dict[@"dateLastAccessed"] = [self iso8601DateString:self.dateLastAccessed];
    }
    if (self.dateRetrieved) {
        dict[@"dateRetrieved"] = [self iso8601DateString:self.dateRetrieved];
    }
    if (self.mimeType) {
        dict[@"mimeType"] = self.mimeType;
    }
    if (self.width) {
        dict[@"width"] = self.width;
    }
    if (self.height) {
        dict[@"height"] = self.height;
    }
    if (self.focalRectsInUnitCoordinatesAsStrings) {
        dict[@"focalRects"] = self.focalRectsInUnitCoordinatesAsStrings;
    }

    return [dict copy];
}

- (void)importImageData:(NSData*)data {
    [self.article.dataStore saveImageData:data image:self];
}

- (void)updateWithData:(NSData*)data {
    self.dateRetrieved    = [[NSDate alloc] init];
    self.dateLastAccessed = [[NSDate alloc] init];
    self.mimeType         = [self getImageMimeTypeForExtension:self.extension];

    if (!self.width || !self.height) {
        UIImage* img = [UIImage imageWithData:data];
        self.width  = [NSNumber numberWithInt:img.size.width];
        self.height = [NSNumber numberWithInt:img.size.height];
    }
}

- (NSString*)getImageMimeTypeForExtension:(NSString*)extension {
    NSString* lowerCaseSelf = [extension lowercaseString];
    if ([lowerCaseSelf isEqualToString:@"jpg"]) {
        return @"image/jpeg";
    }
    if ([lowerCaseSelf isEqualToString:@"jpeg"]) {
        return @"image/jpeg";
    }
    if ([lowerCaseSelf isEqualToString:@"png"]) {
        return @"image/png";
    }
    if ([lowerCaseSelf isEqualToString:@"gif"]) {
        return @"image/gif";
    }
    return @"";
}

- (void)updateLastAccessed {
    self.dateLastAccessed = [[NSDate alloc] init];
}

- (void)save {
    [self.article.dataStore saveImage:self];
}

- (UIImage*)asUIImage {
    NSData* imageData = [self asNSData];

    UIImage* image = [UIImage imageWithData:imageData];

    NSAssert((![self hasEstimatedSize] || [self isEstimatedSizeWithinPoints:10.f ofSize:image.size]),
             (@"estimatedSize inaccuracy has exceeded acceptable threshold: { \n"
              "\t" "sourceURL: %@, \n"
              "\t" "estimatedSize: %@ \n"
              "\t" "actualSize: %@ \n"
              "}"),
             self.sourceURL, [self estimatedSizeString], NSStringFromCGSize(image.size));

    return image;
}

- (BOOL)hasEstimatedSize {
    return self.width && self.height;
}

- (CGSize)estimatedSize {
    if ([self hasEstimatedSize]) {
        return CGSizeMake(self.width.floatValue, self.height.floatValue);
    } else {
        return CGSizeZero;
    }
}

- (NSString*)estimatedSizeString {
    return NSStringFromCGSize(self.estimatedSize);
}

/// @return @c YES if @c size is within @c points of <code>self.estimatedSize</code>, otherwise @c NO.
- (BOOL)isEstimatedSizeWithinPoints:(float)points ofSize:(CGSize)size {
    CGSize estimatedSize = [self estimatedSize];
    return fabs(estimatedSize.width - size.width) <= points
           && fabs(estimatedSize.height - size.height) <= points;
}

- (NSData*)asNSData {
    return [self.article.dataStore imageDataWithImage:self];
}

- (MWKImage*)largestVariant {
    NSString* largestURL = [self.article.images largestImageVariant:self.sourceURL];
    return [self.article imageWithURL:largestURL];
}

- (MWKImage*)smallestVariant {
    NSString* smallestURL = [self.article.images smallestImageVariant:self.sourceURL];
    return [self.article imageWithURL:smallestURL];
}

- (MWKImage*)largestCachedVariant {
    return [self.article.images largestImageVariantForURL:self.sourceURL cachedOnly:YES];
}

- (MWKImage*)smallestCachedVariant {
    return [self.article.images smallestImageVariantForURL:self.sourceURL cachedOnly:YES];
}

- (BOOL)isCached {
    NSString* fullPath = [self fullImageBinaryPath];
    BOOL fileExists    = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
    return fileExists;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKImage class]]) {
        return [self isEqualToImage:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToImage:(MWKImage*)image {
    return self == image || [self.fileName isEqualToString:image.fileName];
}

- (NSUInteger)hash {
    return [self.fileName hash];
}

- (BOOL)isVariantOfImage:(MWKImage*)otherImage {
    // !!!: this might not be reliable due to underscore, percent encodings, and other unknowns w/ image filenames
    return [self.fileNameNoSizePrefix isEqualToString:otherImage.fileNameNoSizePrefix]
           && ![self isEqualToImage:otherImage];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ article: %@ sourceURL: %@",
            [super description], self.article.title, self.sourceURL];
}

- (NSString*)fullImageBinaryPath {
    NSString* path     = [self.article.dataStore pathForImage:self];
    NSString* fileName = [@"Image" stringByAppendingPathExtension:self.extension];
    NSString* filePath = [path stringByAppendingPathComponent:fileName];
    return filePath;
}

- (BOOL)isLeadImage {
    return [self.article.image isEqualToImage:self];
}

@end
