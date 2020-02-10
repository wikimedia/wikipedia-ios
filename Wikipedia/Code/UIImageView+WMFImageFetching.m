#import <WMF/UIImageView+WMFImageFetching.h>
#import "UIImageView+WMFImageFetchingInternal.h"
#import "UIImageView+WMFContentOffset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIImageView (WMFImageFetching)

- (void)wmf_reset {
    self.image = nil;
    [self wmf_resetContentsRect];
    [self wmf_cancelImageDownload];
}

- (void)wmf_setImageWithURL:(NSURL *)imageURL detectFaces:(BOOL)detectFaces onGPU:(BOOL)onGPU failure:(nonnull WMFErrorHandler)failure success:(nonnull WMFSuccessHandler)success {
    [self wmf_cancelImageDownload];
    self.wmf_imageURL = imageURL;
    [self wmf_fetchImageDetectFaces:detectFaces onGPU:onGPU failure:failure success:success];
}

- (nullable NSURL *)wmf_imageURLToFetch {
    return self.wmf_imageURL;
}

@end

NS_ASSUME_NONNULL_END
