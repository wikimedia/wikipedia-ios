@import UIKit;
@import WMFModel;

@class MWKImage;

@interface WMFFaceDetectionCache : NSObject

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL *)url;
- (void)detectFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU URL:(NSURL *)url failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success;
- (NSValue *)faceBoundsForURL:(NSURL *)url;

- (BOOL)imageRequiresFaceDetection:(MWKImage *)imageMetadata;
- (void)detectFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU imageMetadata:(MWKImage *)imageMetadata failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success;
- (NSValue *)faceBoundsForImageMetadata:(MWKImage *)imageMetadata;

- (void)clearCache;

@end
