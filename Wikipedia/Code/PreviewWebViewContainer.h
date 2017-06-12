@import WebKit;
@import WMF.MWLanguageInfo;
#import "WMFOpenExternalLinkDelegateProtocol.h"

@protocol WMFPreviewSectionLanguageInfoDelegate

- (nullable MWLanguageInfo *)wmf_editedSectionLanguageInfo;

@end

@protocol WMFPreviewAnchorTapAlertDelegate

- (void)wmf_showAlertForTappedAnchorHref:(nullable NSString *)href;

@end

NS_ASSUME_NONNULL_BEGIN

@interface PreviewWebViewContainer : UIView <WKNavigationDelegate>

@property (weak, nonatomic) id<WMFOpenExternalLinkDelegate> externalLinksOpenerDelegate;
@property (strong, nonatomic) WKWebView *webView;

@property (weak, nonatomic) IBOutlet id<WMFPreviewSectionLanguageInfoDelegate> previewSectionLanguageInfoDelegate;
@property (weak, nonatomic) IBOutlet id<WMFPreviewAnchorTapAlertDelegate> previewAnchorTapAlertDelegate;

@end

NS_ASSUME_NONNULL_END
