#import <Foundation/Foundation.h>

@interface NSDictionary (WMFCommonParams)

+ (instancetype)wmf_titlePreviewRequestParameters;

+ (instancetype)wmf_titlePreviewRequestParametersWithExtractLength:(NSUInteger)extractLength
                                                        imageWidth:(NSNumber*)imageWidth;

@end
