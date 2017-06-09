#import "WebViewController.h"

#import <WMF/SessionSingleton.h>
#import <WMF/MWLanguageInfo.h>
#import "WKWebView+ElementLocation.h"
#import "PaddedLabel.h"
#import "EditFunnel.h"
#import "NSString+FormattedAttributedString.h"
#import "SavedPagesFunnel.h"

#import "UIFont+WMFStyle.h"

#import "UIScrollView+WMFScrollsToTop.h"
#import <WMF/WMFURLCache.h>

#import <WMF/MWKHistoryEntry.h>

// TODO: rename the WebViewControllerVariableNames once we rename this class
NS_ASSUME_NONNULL_BEGIN

@interface WebViewController ()

@property (nonatomic, strong, readwrite, nullable) WKWebView *webView;

@property (nonatomic, strong, nullable, readwrite) MWKArticle *article;
@property (nonatomic, strong, nullable, readwrite) NSURL *articleURL;

@property (nonatomic, strong) SessionSingleton *session;

@property (strong, nonatomic) NSDictionary *adjacentHistoryIDs;
@property (strong, nonatomic) NSString *externalUrl;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tocViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tocViewLeadingConstraint;

@property (strong, nonatomic) IBOutlet PaddedLabel *zeroStatusLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewBottomConstraint;

@property (nonatomic, strong) SavedPagesFunnel *savedPagesFunnel;

/**
 * Designated initializer.
 * @param session The current session, defaults to `+[SessionSingleton sharedInstance]`.
 * @return A new `WebViewController` with the given session.
 */
- (instancetype)initWithSession:(SessionSingleton *)session;

@end

NS_ASSUME_NONNULL_END
