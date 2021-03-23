@import UIKit;
@import WMF.Swift;
@class MWKLanguageLink;
@class WMFLanguagesViewController;
@protocol WMFLanguagesViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WMFThemeable>

@property (nonatomic, weak, nullable) id<WMFLanguagesViewControllerDelegate> delegate;

+ (instancetype)languagesViewController;

+ (instancetype)nonPreferredLanguagesViewController;

@property (nonatomic, assign) BOOL showExploreFeedCustomizationSettings;

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

@end

NS_ASSUME_NONNULL_END
