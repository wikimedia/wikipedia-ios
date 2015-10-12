
#import "UIImageView+WMFImageFetchingInternal.h"
#import "UIImageView+WMFContentOffset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIImageView (WMFImageFetching)

- (void)wmf_reset {
    self.image = nil;
    [self wmf_resetContentsRect];
    [self wmf_cancelImageDownload];
    self.wmf_imageURL      = nil;
    self.wmf_imageMetadata = nil;
}

- (AnyPromise*)wmf_setImageWithURL:(NSURL*)imageURL detectFaces:(BOOL)detectFaces {
    [self wmf_cancelImageDownload];
    self.wmf_imageURL      = imageURL;
    self.wmf_imageMetadata = nil;
    return [self wmf_fetchImageDetectFaces:detectFaces];
}

- (AnyPromise*)wmf_setImageWithMetadata:(MWKImage*)imageMetadata detectFaces:(BOOL)detectFaces {
    [self wmf_cancelImageDownload];
    self.wmf_imageMetadata = imageMetadata;
    self.wmf_imageURL      = nil;
    return [self wmf_fetchImageDetectFaces:detectFaces];
}

@end


NS_ASSUME_NONNULL_END
