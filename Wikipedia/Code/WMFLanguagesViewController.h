
#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"

@class MWKLanguageLink;
@class WMFLanguagesViewController;

/*
 * Protocol for notifying languageSelectionDelegate that selection was made.
 * It is the receiver's responsibility to perform the appropriate action and dismiss the sender.
 */
@protocol WMFLanguagesViewControllerDelegate <NSObject>

@optional
- (void)languagesController:(WMFLanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language;

@end

@interface WMFLanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WMFAnalyticsContentTypeProviding>

@property (nonatomic, weak) id <WMFLanguagesViewControllerDelegate> delegate;

+ (instancetype)languagesViewController;

+ (instancetype)nonPreferredLanguagesViewController;

@end


@class WMFPreferredLanguagesViewController;

@protocol WMFPreferredLanguagesViewControllerDelegate <WMFLanguagesViewControllerDelegate>

@optional
- (void)languagesController:(WMFPreferredLanguagesViewController*)controller didUpdatePreferredLanguages:(NSArray<MWKLanguageLink*>*)languages;

@end

@interface WMFPreferredLanguagesViewController : WMFLanguagesViewController

+ (instancetype)preferredLanguagesViewController;

@property (nonatomic, weak) id <WMFPreferredLanguagesViewControllerDelegate> delegate;

@end


@class MWKTitle, MWKLanguageLink;

@interface WMFArticleLanguagesViewController : WMFLanguagesViewController

+ (instancetype)articleLanguagesViewControllerWithTitle:(MWKTitle*)title;

@property (nonatomic, strong, readonly) MWKTitle* articleTitle;


@end

