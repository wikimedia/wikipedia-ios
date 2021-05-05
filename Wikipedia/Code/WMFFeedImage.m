#import <WMF/WMFFeedImage.h>
#import <WMF/WMFComparison.h>
#import <WMF/WMFImageURLParsing.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/MWKLanguageLinkController.h>
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
        // The image description service returns a language but not a language variant code.
        // The language variant in the request is currenty not taken into account in the response.
        // So using the language code is correct in this case.
        return @([MWKLanguageLinkController isLanguageRTLForContentLanguageCode:lang]);
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
    double maxScale = MAX(widthScale, heightScale);
    NSInteger targetWidth = imageWidth * maxScale;
    NSInteger targetHeight = imageHeight * maxScale;
    // The thumbnail service only constrains the width. In the case of a vertical panorama this
    // could lead to downloading a very large image. To work around this, limit the maximum height.
    NSInteger heightLimit = 1.5 * WMFImageWidthExtraExtraLarge;
    if (targetHeight >  heightLimit) {
        double scaleDownForTooTallImage = (double)heightLimit / targetHeight;
        targetWidth = targetWidth * scaleDownForTooTallImage;
    }
    if (targetWidth > imageWidth) {
        // We can't request a width larger than the original width, so return the original image URL
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
    NSURL *adjustedURL = [NSURL URLWithString:adjustedString];
    return adjustedURL ?: self.imageThumbURL ?: self.imageURL;
}

// No languageVariantCodePropagationSubelementKeys

+ (NSArray<NSString *> *)languageVariantCodePropagationURLKeys {
    return @[@"imageThumbURL", @"imageURL"];
}

@end

NS_ASSUME_NONNULL_END
