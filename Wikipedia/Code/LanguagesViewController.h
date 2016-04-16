
#import <UIKit/UIKit.h>
#import "WMFAnalyticsLogging.h"

@class MWKArticle;
@class MWKLanguageLink;
@class LanguagesViewController;

/*
 * Protocol for notifying languageSelectionDelegate that selection was made.
 * It is the receiver's responsibility to perform the appropriate action and dismiss the sender.
 */
@protocol LanguageSelectionDelegate <NSObject>

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language;

@end

@interface LanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WMFAnalyticsContentTypeProviding>

/**
 *  Article title must be set before the view controller is displayed.
 *  Setting the article title afterwards is unsupported.
 */
@property (nonatomic, strong) MWKTitle* articleTitle;

@property (nonatomic, assign) BOOL showPreferredLanguges;
@property (nonatomic, assign) BOOL showNonPreferredLanguges;

@property (strong, nonatomic) IBOutlet UITableView* tableView;

// Object to receive "languageSelected:sender:" notifications.
@property (nonatomic, weak) id <LanguageSelectionDelegate> languageSelectionDelegate;

@property (nonatomic) BOOL editing;

@end
