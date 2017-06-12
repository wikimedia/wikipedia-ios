@import WMF.WMFApiJsonResponseSerializer;

@interface MWKImageInfoResponseSerializer : WMFApiJsonResponseSerializer

+ (NSArray<NSString *> *)galleryExtMetadataKeys;

+ (NSArray<NSString *> *)picOfTheDayExtMetadataKeys;

@end
