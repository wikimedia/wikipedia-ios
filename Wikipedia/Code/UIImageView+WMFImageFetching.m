#import <WMF/UIImageView+WMFImageFetching.h>
#import "UIImageView+WMFImageFetchingInternal.h"
#import "UIImageView+WMFContentOffset.h"
#import <objc/runtime.h>
#import <WMF/MWKDataStore.h>

NS_ASSUME_NONNULL_BEGIN

static const char *const WMFImageControllerAssociationKey = "WMFImageControllerAssociationKey";

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

- (WMFPermanentCacheController *__nullable)wmf_imageController {
    WMFPermanentCacheController *controller = objc_getAssociatedObject(self, WMFImageControllerAssociationKey);
    if (!controller) {
        controller = [MWKDataStore shared].cacheController;
    }
    return controller;
}

- (void)wmf_setImageController:(nullable WMFPermanentCacheController *)imageController {
    objc_setAssociatedObject(self, WMFImageControllerAssociationKey, imageController, OBJC_ASSOCIATION_ASSIGN);
}

@end

NS_ASSUME_NONNULL_END
