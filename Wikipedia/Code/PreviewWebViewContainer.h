//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@import WebKit;
#import "WMFOpenExternalLinkDelegateProtocol.h"
#import "MWLanguageInfo.h"

@protocol WMFPreviewSectionLanguageInfoDelegate

- (nullable MWLanguageInfo*)wmf_editedSectionLanguageInfo;

@end

@protocol WMFPreviewAnchorTapAlertDelegate

- (void)wmf_showAlertForTappedAnchorHref:(nullable NSString*)href;

@end

NS_ASSUME_NONNULL_BEGIN

@interface PreviewWebViewContainer : UIView <WKNavigationDelegate>

@property (weak, nonatomic) id <WMFOpenExternalLinkDelegate> externalLinksOpenerDelegate;
@property (strong, nonatomic) WKWebView* webView;

@property (weak, nonatomic) IBOutlet id <WMFPreviewSectionLanguageInfoDelegate> previewSectionLanguageInfoDelegate;
@property (weak, nonatomic) IBOutlet id <WMFPreviewAnchorTapAlertDelegate> previewAnchorTapAlertDelegate;

@end

NS_ASSUME_NONNULL_END