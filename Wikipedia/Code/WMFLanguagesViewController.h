@import UIKit;
@import WMF.Swift;
@class MWKLanguageLink;
@class WMFLanguagesViewController;

/*
 * Protocol for notifying languageSelectionDelegate that selection was made.
 * It is the receiver's responsibility to perform the appropriate action and dismiss the sender.
 */
@protocol WMFLanguagesViewControllerDelegate <NSObject>

@optional
- (void)languagesController:(WMFLanguagesViewController *)controller didSelectLanguage:(MWKLanguageLink *)language;

@end

@interface WMFLanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WMFAnalyticsContentTypeProviding, WMFThemeable>

@property (nonatomic, weak) id<WMFLanguagesViewControllerDelegate> delegate;

+ (instancetype)languagesViewController;

+ (instancetype)nonPreferredLanguagesViewController;

@end

@class WMFPreferredLanguagesViewController;

@protocol WMFPreferredLanguagesViewControllerDelegate <WMFLanguagesViewControllerDelegate>

@optional
- (void)languagesController:(WMFPreferredLanguagesViewController *)controller didUpdatePreferredLanguages:(NSArray<MWKLanguageLink *> *)languages;

@end

@interface WMFPreferredLanguagesViewController : WMFLanguagesViewController

+ (instancetype)preferredLanguagesViewController NS_SWIFT_NAME(preferredLanguagesViewController());

@property (nonatomic, weak) id<WMFPreferredLanguagesViewControllerDelegate> delegate;

@end

@class MWKLanguageLink;

@interface WMFArticleLanguagesViewController : WMFLanguagesViewController

+ (instancetype)articleLanguagesViewControllerWithArticleURL:(NSURL *)url;

@property (nonatomic, strong, readonly) NSURL *articleURL;

@end
