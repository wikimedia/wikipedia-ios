
#import <UIKit/UIKit.h>
@import MGSwipeTableCell;

@interface WMFWelcomeLanguageTableViewCell : MGSwipeTableCell

@property (strong, nonatomic) IBOutlet UILabel* languageNameLabel;

@property (strong, nonatomic) IBOutlet UIButton* minusButton;

@property (copy, nonatomic) dispatch_block_t deleteButtonTapped;

@end
