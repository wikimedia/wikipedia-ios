#import <WMF/WMFImageTag.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFImageTag ()

@property (nonatomic, copy, readwrite, nullable) NSString *srcset;
@property (nonatomic, copy, readwrite, nullable) NSString *alt;
@property (nonatomic, strong, readwrite, nullable) NSNumber *width;
@property (nonatomic, strong, readwrite, nullable) NSNumber *height;
@property (nonatomic, strong, readwrite, nullable) NSNumber *dataFileWidth;
@property (nonatomic, strong, readwrite, nullable) NSNumber *dataFileHeight;

@property (nonatomic, strong) NSMutableDictionary *additionalAttributes;

@property (nonatomic) NSRange originalImageTagContentsSrcAttributeRange;
@property (nonatomic, copy) NSString *originalImageTagContents;

@end

@implementation WMFImageTag

- (nullable instancetype)initWithSrc:(NSString *)src
                              srcset:(nullable NSString *)srcset
                                 alt:(nullable NSString *)alt
                               width:(nullable NSString *)width
                              height:(nullable NSString *)height
                       dataFileWidth:(nullable NSString *)dataFileWidth
                      dataFileHeight:(nullable NSString *)dataFileHeight
                             baseURL:(nullable NSURL *)baseURL {
    NSParameterAssert(src);
    if (!src) {
        return nil;
    }
    if ([[src stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        return nil;
    }

    NSURLComponents *srcURLComponents = [NSURLComponents componentsWithString:src];
    if (srcURLComponents == nil) {
        return nil;
    }

    // remove scheme for consistency.
    if (srcURLComponents.scheme != nil) {
        srcURLComponents.scheme = nil;
    }

    if (srcURLComponents.host == nil) {
        if (![src hasPrefix:@"/"]) {
            srcURLComponents.path = [baseURL.path stringByAppendingPathComponent:src];
        }
        srcURLComponents.host = baseURL.host;
    }

    src = srcURLComponents.URL.absoluteString;
    if (src == nil) {
        return nil;
    }

    self = [super init];
    if (self) {
        self.src = src;
        self.srcset = srcset;
        self.alt = alt;
        self.width = [width isEqual:[NSNull null]] ? nil : @([width integerValue]);
        self.height = [height isEqual:[NSNull null]] ? nil : @([height integerValue]);
        self.dataFileWidth = [dataFileWidth isEqual:[NSNull null]] ? nil : @([dataFileWidth integerValue]);
        self.dataFileHeight = [dataFileHeight isEqual:[NSNull null]] ? nil : @([dataFileHeight integerValue]);
    }
    return self;
}

- (nullable instancetype)initWithImageTagContents:(NSString *)imageTagContents baseURL:(nullable NSURL *)baseURL {
    static NSRegularExpression *attributeRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *attributePattern = @"(src|data-file-width|width|data-file-height|height)=[\"']?((?:.(?![\"']?\\s+(?:\\S+)=|[>\"']))+.)[\"']?"; //match on the attributes we need to read: src, data-file-width, width, etc
        attributeRegex = [NSRegularExpression regularExpressionWithPattern:attributePattern options:NSRegularExpressionCaseInsensitive error:nil];
    });

    __block NSString *src = nil;                                    //the image src
    __block NSRange srcAttributeRange = NSMakeRange(NSNotFound, 0); //the range of the full src attribute - src=blah
    __block NSString *dataFileWidth = 0;                            //the original file width from data-file-width=
    __block NSString *width = 0;                                    //the width of the image from width=
    __block NSString *dataFileHeight = 0;                           //the original file height from data-file-height=
    __block NSString *height = 0;                                   //the height of the image from height=
    NSInteger attributeOffset = 0;
    [attributeRegex enumerateMatchesInString:imageTagContents
                                     options:0
                                       range:NSMakeRange(0, imageTagContents.length)
                                  usingBlock:^(NSTextCheckingResult *_Nullable attributeResult, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                      NSString *attributeName = [[attributeRegex replacementStringForResult:attributeResult inString:imageTagContents offset:attributeOffset template:@"$1"] lowercaseString];
                                      NSString *attributeValue = [attributeRegex replacementStringForResult:attributeResult inString:imageTagContents offset:attributeOffset template:@"$2"];
                                      if ([attributeName isEqualToString:@"src"]) {
                                          src = attributeValue;
                                          srcAttributeRange = attributeResult.range;
                                      } else if ([attributeName isEqualToString:@"data-file-width"]) {
                                          dataFileWidth = attributeValue;
                                      } else if ([attributeName isEqualToString:@"width"]) {
                                          width = attributeValue;
                                      } else if ([attributeName isEqualToString:@"data-file-height"]) {
                                          dataFileHeight = attributeValue;
                                      } else if ([attributeName isEqualToString:@"height"]) {
                                          height = attributeValue;
                                      }
                                      *stop = width && height && dataFileWidth && dataFileHeight && src && srcAttributeRange.location != NSNotFound;
                                  }];

    //Don't continue initialization if we have invalid src
    if ([src length] == 0) {
        return nil;
    }

    self.originalImageTagContentsSrcAttributeRange = srcAttributeRange;
    self.originalImageTagContents = imageTagContents;

    return [self initWithSrc:src srcset:nil alt:nil width:width height:height dataFileWidth:dataFileWidth dataFileHeight:dataFileHeight baseURL:baseURL];
}

- (BOOL)isSizeLargeEnoughForGalleryInclusion {
    return
        // Ensure images which are just used as tiny icons are not included in gallery.
        self.width.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.width &&
        self.height.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.height &&
        // Also make sure we only try to show them in the gallery if their canonical size is of sufficient resolution.
        self.dataFileWidth.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.width &&
        self.dataFileHeight.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.height;
}

- (NSString *)description {
    return [NSString stringWithFormat:@""
                                       "\n\n "
                                       "image tag: \n\t "
                                       "src = %@ \n\t "
                                       "srcset = %@ \n\t "
                                       "alt = %@ \n\t "
                                       "width = %@ \n\t "
                                       "height = %@ \n\t "
                                       "dataFileWidth = %@ \n\t "
                                       "dataFileHeight = %@ \n",
                                      self.src,
                                      self.srcset,
                                      self.alt,
                                      self.width,
                                      self.height,
                                      self.dataFileWidth,
                                      self.dataFileHeight];
}

- (NSString *)imageTagContents {
    NSString *newImageTagContents = nil;
    NSMutableDictionary *attributes = [self.additionalAttributes mutableCopy];

    if (self.originalImageTagContents && self.originalImageTagContentsSrcAttributeRange.location != NSNotFound) {
        newImageTagContents = [self.originalImageTagContents stringByReplacingCharactersInRange:self.originalImageTagContentsSrcAttributeRange withString:self.src]; //only src is settable
    } else {
        newImageTagContents = @"";
        attributes[@"src"] = self.src;
        attributes[@"srcset"] = self.srcset;
        attributes[@"alt"] = self.alt;
        attributes[@"width"] = self.width;
        attributes[@"height"] = self.height;
        attributes[@"data-file-width"] = self.dataFileWidth;
        attributes[@"data-file-height"] = self.dataFileHeight;
    }

    for (NSString *attribute in attributes) {
        NSString *value = attributes[attribute];
        if (value) {
            NSString *attributeString = [@[@" ", attribute, @"=", value] componentsJoinedByString:@""];
            newImageTagContents = [newImageTagContents stringByAppendingString:attributeString];
        }
    }

    return newImageTagContents;
}

- (void)setValue:(NSString *)value forAttribute:(NSString *)attribute {
    if (!self.additionalAttributes) {
        self.additionalAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    _additionalAttributes[attribute] = value;
}

@end

NS_ASSUME_NONNULL_END
