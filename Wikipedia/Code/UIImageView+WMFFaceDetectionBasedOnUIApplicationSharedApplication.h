@import WMFModel;

@interface UIImageView (WMFFaceDetectionBasedOnUIApplicationSharedApplication)

- (void)wmf_setImageWithURL:(NSURL *)imageURL detectFaces:(BOOL)detectFaces failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;
- (void)wmf_setImageWithMetadata:(MWKImage *)imageMetadata detectFaces:(BOOL)detectFaces failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

@end
