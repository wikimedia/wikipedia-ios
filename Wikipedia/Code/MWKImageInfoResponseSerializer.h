#import <WMF/WMFApiJsonResponseSerializer.h>

@interface MWKImageInfoResponseSerializer : WMFApiJsonResponseSerializer

+ (NSArray<NSString *> *)galleryExtMetadataKeys;

+ (NSArray<NSString *> *)picOfTheDayExtMetadataKeys;

@end
