#import <WMF/WMFFeedImage.h>
#import <WMF/WMFComparison.h>
#import <WMF/WMFImageURLParsing.h>
#import <WMF/NSURL+WMFExtras.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedImage

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFFeedImage.new, canonicalPageTitle): @"title",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageDescription): @"description.text",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageURL): @"image.source",
             WMF_SAFE_KEYPATH(WMFFeedImage.new, imageThumbURL): @"thumbnail.source"};
}

+ (NSValueTransformer *)imageThumbURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSString *urlString,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            NSInteger sizePrefix = WMFParseSizePrefixFromSourceURL(urlString);
            if (sizePrefix < 640) {
                urlString = WMFChangeImageSourceURLSizePrefix(urlString, 640);
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

@end

NS_ASSUME_NONNULL_END
