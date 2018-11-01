@import UIKit;
#import <WMF/WMFBlockDefinitions.h>

@interface WMFFaceDetectionCache : NSObject

+ (WMFFaceDetectionCache *)sharedCache;

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL *)url;
- (void)detectFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU URL:(NSURL *)url failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success;
- (NSValue *)faceBoundsForURL:(NSURL *)url;

- (void)cancelFaceDetectionForURL:(NSURL *)url;

- (void)clearCache;

@end
