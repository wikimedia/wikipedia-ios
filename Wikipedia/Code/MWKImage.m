#import <WMF/MWKImage.h>
#import <WMF/WMFImageURLParsing.h>
#import <WMF/WMFGeometry.h>
#import <WMF/WMF-Swift.h>

@interface MWKImage ()

///
/// readwrite redeclarations
///

@property (readwrite, weak, nonatomic) MWKArticle *article;
@property (readwrite, copy, nonatomic) NSURL *sourceURL;
@property (readwrite, assign, nonatomic) BOOL isCached;

///
/// Lazy property storage
///

@property (readwrite, copy, nonatomic) NSString *extension;
@property (readwrite, copy, nonatomic) NSString *fileName;
@property (readwrite, copy, nonatomic) NSString *fileNameNoSizePrefix;

@end

@implementation MWKImage

- (instancetype)initWithArticle:(MWKArticle *)article sourceURLString:(NSString *)urlString {
    return [self initWithArticle:article sourceURL:[NSURL wmf_optionalURLWithString:urlString]];
}

- (instancetype)initWithArticle:(MWKArticle *)article sourceURL:(NSURL *)sourceURL {
    self = [super initWithURL:article.url];
    if (self) {
        self.article = article;

        // fileNameNoSizePrefix is lazily derived from this property, so be careful if _sourceURL needs to be re-set
        NSParameterAssert(sourceURL.absoluteString.length);
        self.sourceURL = sourceURL;
    }
    return self;
}

#pragma mark - Serialization

- (instancetype)initWithArticle:(MWKArticle *)article dict:(NSDictionary *)dict {
    NSString *sourceURL = [self requiredString:@"sourceURL" dict:dict];
    self = [self initWithArticle:article sourceURLString:sourceURL];
    if (self) {
        self.mimeType = [self optionalString:@"mimeType" dict:dict];
        self.width = [self optionalNumber:@"width" dict:dict];
        self.height = [self optionalNumber:@"height" dict:dict];
        self.originalFileWidth = [self optionalNumber:@"originalFileWidth" dict:dict];
        self.originalFileHeight = [self optionalNumber:@"originalFileHeight" dict:dict];
    }
    return self;
}

#pragma mark - Accessors

- (NSString *)sourceURLString {
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

- (NSString *)extension {
    return [self.sourceURLString pathExtension];
}

- (NSString *)fileName {
    return [self.sourceURLString lastPathComponent];
}

- (NSString *)basename {
    NSArray *sourceURLComponents = [self.sourceURLString componentsSeparatedByString:@"/"];
    NSParameterAssert(sourceURLComponents.count >= 2);
    return sourceURLComponents[sourceURLComponents.count - 2];
}

- (NSString *)canonicalFilename {
    return WMFParseUnescapedNormalizedImageNameFromSourceURL(self.sourceURL);
}

- (NSString *)fileNameNoSizePrefix {
    if (!_fileNameNoSizePrefix) {
        _fileNameNoSizePrefix = WMFParseImageNameFromSourceURL(self.sourceURLString);
    }
    return _fileNameNoSizePrefix;
}

#pragma mark - Import / Export

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

- (NSString *)estimatedSizeString {
    return NSStringFromCGSize(self.estimatedSize);
}

/// @return @c YES if @c size is within @c points of <code>self.estimatedSize</code>, otherwise @c NO.
- (BOOL)isEstimatedSizeWithinPoints:(float)points ofSize:(CGSize)size {
    CGSize estimatedSize = [self estimatedSize];
    return fabs(estimatedSize.width - size.width) <= points && fabs(estimatedSize.height - size.height) <= points;
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

- (BOOL)isEqualToImage:(MWKImage *)image {
    return self == image || [[self.sourceURLString wmf_schemelessURL] isEqualToString:[image.sourceURLString wmf_schemelessURL]];
}

- (NSUInteger)hash {
    return [self.fileName hash];
}

- (BOOL)isVariantOfImage:(MWKImage *)otherImage {
    return otherImage.canonicalFilename && [self.canonicalFilename isEqualToString:otherImage.canonicalFilename];
}

- (NSString *)description {
    //Do not use MTLModel's description as it will cause recursion since this instance has a reference to the article, which also has a reference to this image
    return [NSString stringWithFormat:@"article: %@ sourceURL: %@", self.article.url, self.sourceURLString];
}

- (BOOL)isLeadImage {
    return [self.article.image isEqualToImage:self];
}

- (BOOL)isCanonical {
    return WMFParseSizePrefixFromSourceURL(self.sourceURLString) == NSNotFound;
}

@end
