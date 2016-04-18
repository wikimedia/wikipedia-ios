
#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"

@class MWKLanguageLink;
@class LanguagesViewController;

/*
 * Protocol for notifying languageSelectionDelegate that selection was made.
 * It is the receiver's responsibility to perform the appropriate action and dismiss the sender.
 */
@protocol WMFLanguagesViewControllerDelegate <NSObject>

@optional
- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language;

@end

@interface LanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WMFAnalyticsContentTypeProviding>

@property (nonatomic, weak) id <WMFLanguagesViewControllerDelegate> delegate;

+ (instancetype)languagesViewController;

+ (instancetype)nonPreferredLanguagesViewController;

@end


@class WMFPreferredLanguagesViewController;

@protocol WMFPreferredLanguagesViewControllerDelegate <WMFLanguagesViewControllerDelegate>

- (void)languagesController:(WMFPreferredLanguagesViewController*)controller didUpdatePreferredLanguages:(NSArray<MWKLanguageLink*>*)languages;

@end

@interface WMFPreferredLanguagesViewController : LanguagesViewController

+ (instancetype)preferredLanguagesViewController;

@property (nonatomic, weak) id <WMFPreferredLanguagesViewControllerDelegate> delegate;

@end


@class MWKTitle, MWKLanguageLink;

@interface WMFArticleLanguagesViewController : LanguagesViewController

+ (instancetype)articleLanguagesViewControllerWithTitle:(MWKTitle*)title;

@property (nonatomic, strong, readonly) MWKTitle* articleTitle;


@end

