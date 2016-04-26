#import "WMFTableViewCellWithCustomMinusButton.h"

#import <UIKit/UIKit.h>

@interface WMFWelcomeLanguageTableViewCell : WMFTableViewCellWithCustomMinusButton

@property (strong, nonatomic) IBOutlet UILabel* languageNameLabel;

@property (copy, nonatomic) dispatch_block_t deleteButtonTapped;

@end
