#import <Foundation/Foundation.h>

@class MWKImage;

@interface WMFFaceDetectionCache : NSObject

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL *)url;
- (void)detectFaceBoundsInImage:(UIImage *)image
                            URL:(NSURL *)url
                        failure:(WMFErrorHandler)failure
                        success:(WMFSuccessNSValueHandler)success;
- (NSValue *)faceBoundsForURL:(NSURL *)url;

- (BOOL)imageRequiresFaceDetection:(MWKImage *)imageMetadata;
- (void)detectFaceBoundsInImage:(UIImage *)image
                  imageMetadata:(MWKImage *)imageMetadata
                        failure:(WMFErrorHandler)failure
                        success:(WMFSuccessNSValueHandler)success;
- (NSValue *)faceBoundsForImageMetadata:(MWKImage *)imageMetadata;

- (void)clearCache;

@end
