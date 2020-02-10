#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
@import WMF;

NS_ASSUME_NONNULL_BEGIN

@implementation UIImageView (WMFFaceDetectionBasedOnUIApplicationSharedApplication)

- (void)wmf_setImageWithURL:(NSURL *)imageURL {
    [self wmf_setImageWithURL:imageURL
                  detectFaces:YES
                      failure:^(NSError *error) {
                      }
                      success:^{
                      }];
}

- (void)wmf_setImageWithURL:(NSURL *)imageURL detectFaces:(BOOL)detectFaces failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    BOOL isActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    [self wmf_setImageWithURL:imageURL detectFaces:detectFaces onGPU:isActive failure:failure success:success];
}

@end

NS_ASSUME_NONNULL_END
