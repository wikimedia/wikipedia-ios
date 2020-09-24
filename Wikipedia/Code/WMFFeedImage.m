#import <WMF/WMFFeedImage.h>
#import <WMF/WMFComparison.h>
#import <WMF/WMFImageURLParsing.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/MWLanguageInfo.h>
#import <WMF/UIScreen+WMFImageWidth.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedImage

+ (NSUInteger)modelVersion {
    return 3;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFFeedImage.new, canonicalPageTitle): @"title",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageDescription): @"description.text",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageDescriptionIsRTL): @"description.lang",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageURL): @"image.source",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageWidth): @"image.width",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageHeight): @"image.height",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageThumbURL): @"thumbnail.source"};
}

+ (NSValueTransformer *)imageThumbURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSString *urlString,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            NSInteger sizePrefix = WMFParseSizePrefixFromSourceURL(urlString);
            if (sizePrefix < WMFImageWidthExtraLarge) {
                urlString = WMFChangeImageSourceURLSizePrefix(urlString, WMFImageWidthExtraLarge);
            }
            return [NSURL wmf_optionalURLWithString:urlString];
        }
        reverseBlock:^NSString *(NSURL *thumbnailURL,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            return [thumbnailURL absoluteString];
        }];
}

+ (NSValueTransformer *)imageURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSString *urlString,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            return [NSURL wmf_optionalURLWithString:urlString];
        }
        reverseBlock:^NSString *(NSURL *thumbnailURL,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            return [thumbnailURL absoluteString];
        }];
}

+ (NSValueTransformer *)imageDescriptionIsRTLJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *lang, BOOL *success, NSError *__autoreleasing *error) {
        return @(lang && [[MWLanguageInfo rtlLanguages] containsObject:lang]);
    }];
}

- (nullable NSURL *)getImageURLForWidth:(double)width height:(double)height {
    if (!self.imageWidth || !self.imageHeight) {
        return self.imageThumbURL ?: self.imageURL;
    }
    double imageWidth = self.imageWidth.doubleValue;
    double imageHeight = self.imageHeight.doubleValue;
    double widthScale = width / imageWidth;
    double heightScale = height / imageHeight;
    NSInteger targetWidth;
    if (widthScale > heightScale) {
        targetWidth = imageWidth * widthScale;
    } else {
        targetWidth = imageWidth * heightScale;
    }
    if (targetWidth > imageWidth) {
        return self.imageURL;
    }
    NSInteger thumbnailBucketSize;
    if (targetWidth <= WMFImageWidthLarge) {
        thumbnailBucketSize = WMFImageWidthLarge;
    } else if (targetWidth <= WMFImageWidthExtraLarge) {
        thumbnailBucketSize = WMFImageWidthExtraLarge;
    } else {
        thumbnailBucketSize = WMFImageWidthExtraExtraLarge;
    }
    NSString *adjustedString = WMFChangeImageSourceURLSizePrefix(self.imageThumbURL.absoluteString, thumbnailBucketSize);
    NSURL *adujstedURL = [NSURL URLWithString:adjustedString];
    return adujstedURL ?: self.imageThumbURL ?: self.imageURL;
}

@end

NS_ASSUME_NONNULL_END
