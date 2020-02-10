@import UIKit;
@class MWKImage;
#import <WMF/WMFBlockDefinitions.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFFaceDetectionBasedOnUIApplicationSharedApplication)

- (void)wmf_setImageWithURL:(NSURL *)imageURL; // will detect faces
- (void)wmf_setImageWithURL:(NSURL *)imageURL detectFaces:(BOOL)detectFaces failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

@end

NS_ASSUME_NONNULL_END
