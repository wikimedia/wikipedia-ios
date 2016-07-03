
#import "UIKit/UIKit.h"
#import "WikipediaAppUtils.h"
#import "MediaWikiKit.h"
#import "WMFImageURLParsing.h"
#import "WMFGeometry.h"
#import "Wikipedia-Swift.h"
#import "NSURL+WMFExtras.h"

@interface MWKImage ()

///
/// readwrite redeclarations
///

@property (readwrite, weak, nonatomic) MWKArticle* article;
@property (readwrite, copy, nonatomic) NSURL* sourceURL;
@property (readwrite, assign, nonatomic) BOOL isCached;

///
/// Lazy property storage
///

@property (readwrite, copy, nonatomic) NSString* extension;
@property (readwrite, copy, nonatomic) NSString* fileName;
@property (readwrite, copy, nonatomic) NSString* fileNameNoSizePrefix;

@end

@implementation MWKImage

- (instancetype)initWithArticle:(MWKArticle*)article sourceURLString:(NSString*)urlString {
    return [self initWithArticle:article sourceURL:[NSURL wmf_optionalURLWithString:urlString]];
}

- (instancetype)initWithArticle:(MWKArticle*)article sourceURL:(NSURL*)sourceURL {
    self = [super initWithSite:article.site];
    if (self) {
        self.article = article;

        // fileNameNoSizePrefix is lazily derived from this property, so be careful if _sourceURL needs to be re-set
        NSParameterAssert(sourceURL.absoluteString.length);
        self.sourceURL = sourceURL;
    }
    return self;
}

#pragma mark - Serialization

- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict {
    NSString* sourceURL = [self requiredString:@"sourceURL" dict:dict];
    self = [self initWithArticle:article sourceURLString:sourceURL];
    if (self) {
        self.mimeType            = [self optionalString:@"mimeType" dict:dict];
        self.width               = [self optionalNumber:@"width" dict:dict];
        self.height              = [self optionalNumber:@"height" dict:dict];
        self.originalFileWidth   = [self optionalNumber:@"originalFileWidth" dict:dict];
        self.originalFileHeight  = [self optionalNumber:@"originalFileHeight" dict:dict];
        _allNormalizedFaceBounds = [dict[@"focalRects"] bk_map:^NSValue*(NSString* rectString) {
            return [NSValue valueWithCGRect:CGRectFromString(rectString)];
        }];
    }
    return self;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict[@"sourceURL"] = self.sourceURLString;

    if (self.mimeType) {
        dict[@"mimeType"] = self.mimeType;
    }
    if (self.width) {
        dict[@"width"] = self.width;
    }
    if (self.height) {
        dict[@"height"] = self.height;
    }
    if (self.originalFileWidth) {
        dict[@"originalFileWidth"] = self.originalFileWidth;
    }
    if (self.originalFileHeight) {
        dict[@"originalFileHeight"] = self.originalFileHeight;
    }
    if (self.allNormalizedFaceBounds) {
        dict[@"focalRects"] = [self.allNormalizedFaceBounds bk_map:^id (NSValue* rectValue) {
            return NSStringFromCGRect(rectValue.CGRectValue);
        }];
    }

    return [dict copy];
}

#pragma mark - Accessors

- (BOOL)didDetectFaces {
    return self.allNormalizedFaceBounds != nil;
}

- (BOOL)hasFaces {
    return self.allNormalizedFaceBounds.count > 0;
}

- (CGRect)firstFaceBounds {
    NSValue* firstFace = [self.allNormalizedFaceBounds firstObject];
    return firstFace ? [firstFace CGRectValue] : CGRectZero;
}

- (void)setAllNormalizedFaceBounds:(NSArray*)allNormalizedFaceBounds {
    if (!allNormalizedFaceBounds) {
        allNormalizedFaceBounds = @[];
    }
    _allNormalizedFaceBounds = allNormalizedFaceBounds;
}

- (NSString*)sourceURLString {
    return self.sourceURL.absoluteString;
}

- (CGSize)size {
    return CGSizeMake([self.width floatValue], [self.height floatValue]);
}

- (BOOL)hasOriginalFileSize {
    return self.originalFileWidth && self.originalFileHeight;
}

- (CGSize)originalFileSize {
    if ([self hasOriginalFileSize]) {
        return CGSizeMake(self.originalFileWidth.floatValue, self.originalFileHeight.floatValue);
    } else {
        return CGSizeZero;
    }
}

- (NSString*)extension {
    return [self.sourceURLString pathExtension];
}

- (NSString*)fileName {
    return [self.sourceURLString lastPathComponent];
}

- (NSString*)basename {
    NSArray* sourceURLComponents = [self.sourceURLString componentsSeparatedByString:@"/"];
    NSParameterAssert(sourceURLComponents.count >= 2);
    return sourceURLComponents[sourceURLComponents.count - 2];
}

- (NSString*)canonicalFilename {
    return [[self canonicalFilenameFromSourceURL] wmf_unescapedNormalizedPageTitle];
}

- (NSString*)canonicalFilenameFromSourceURL {
    return [MWKImage canonicalFilenameFromSourceURL:self.sourceURLString];
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
        _fileNameNoSizePrefix = [MWKImage fileNameNoSizePrefix:self.sourceURLString];
    }
    return _fileNameNoSizePrefix;
}

#pragma mark - Import / Export

- (void)importImageData:(NSData*)data {
    [self.article.dataStore saveImageData:data image:self];
}

- (void)updateWithData:(NSData*)data {
    self.mimeType = [self getImageMimeTypeForExtension:self.extension];

    if (!self.width || !self.height) {
        UIImage* img = [UIImage imageWithData:data];
        self.width  = [NSNumber numberWithInt:img.size.width];
        self.height = [NSNumber numberWithInt:img.size.height];
    }
}

- (NSString*)getImageMimeTypeForExtension:(NSString*)extension {
    return [self.sourceURL wmf_mimeTypeForExtension];
}

- (void)save {
    [self.article.dataStore saveImage:self];
}

- (UIImage*)asUIImage {
    UIImage* image = [UIImage imageWithData:[self.article.dataStore imageDataWithImage:self]];

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
    return nil;
}

- (BOOL)isDownloaded {
    return [[WMFImageController sharedInstance] hasImageWithURL:[NSURL URLWithString:self.sourceURLString]];
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
            [super description], self.article.title, self.sourceURLString];
}

- (BOOL)isLeadImage {
    return [self.article.image isEqualToImage:self];
}

- (BOOL)isCanonical {
    return [MWKImage fileSizePrefix:self.sourceURLString] == NSNotFound;
}

@end
