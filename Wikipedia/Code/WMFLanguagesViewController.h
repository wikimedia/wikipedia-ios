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

// The showAllLangugages and showPreferredLanguages settings are mutually exclusive.
// Only one of the two should be set to YES.
@property (nonatomic, assign) BOOL showAllLanguages;
@property (nonatomic, assign) BOOL showPreferredLanguages;
@property (nonatomic, assign) BOOL showNonPreferredLanguages;

@property (nonatomic, assign) BOOL showExploreFeedCustomizationSettings;

// Block called after dismissal by user, by tapping the close button,
// and by the accessibility escape gesture
@property (nonatomic, copy, nullable) void (^userDismissalCompletionBlock)(void);

// Block used as a type of completion in scenarios where the delegate method flow isn't sufficient
@property (nonatomic, copy, nullable) void (^userLanguageSelectionBlock)(void);

// Declared so that the method is visible from Swift. Theoretically conforming to WMFThemeable should
// already do that, but it's hard to argue with the compiler.
- (void)applyTheme:(WMFTheme *)theme;

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
