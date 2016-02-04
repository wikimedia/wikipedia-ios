
#import "UIImageView+WMFImageFetchingInternal.h"
#import "UIImageView+WMFContentOffset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIImageView (WMFImageFetching)

- (void)wmf_reset {
    self.image = nil;
    [self wmf_resetContentsRect];
    [self wmf_cancelImageDownload];
}

- (AnyPromise*)wmf_setImageWithURL:(NSURL*)imageURL detectFaces:(BOOL)detectFaces {
    [self wmf_cancelImageDownload];
    self.wmf_imageURL = imageURL;
    return [self wmf_fetchImageDetectFaces:detectFaces];
}

- (AnyPromise*)wmf_setImageWithMetadata:(MWKImage*)imageMetadata detectFaces:(BOOL)detectFaces {
    [self wmf_cancelImageDownload];
    self.wmf_imageMetadata = imageMetadata;
    return [self wmf_fetchImageDetectFaces:detectFaces];
}

@end

NS_ASSUME_NONNULL_END
