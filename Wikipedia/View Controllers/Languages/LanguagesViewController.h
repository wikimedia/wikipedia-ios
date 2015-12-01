
#import <UIKit/UIKit.h>

@class MWKArticle;
@class MWKLanguageLink;
@class LanguagesViewController;

// Protocol for notifying languageSelectionDelegate that selection was made.
@protocol LanguageSelectionDelegate <NSObject>

- (void)languageSelected:(MWKLanguageLink*)langData sender:(LanguagesViewController*)sender;

@end

@interface LanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/**
 *  Article title must be set before the view controller is displayed.
 *  Setting the article title afterwards is unsupported.
 */
@property (nonatomic, strong) MWKTitle* articleTitle;

@property (strong, nonatomic) IBOutlet UITableView* tableView;

// Object to receive "languageSelected:sender:" notifications.
@property (nonatomic, weak) id <LanguageSelectionDelegate> languageSelectionDelegate;

@end
