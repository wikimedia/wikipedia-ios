#import <SSDataSources/SSDataSources.h>

@interface WMFContinueReadingTableViewCell : SSBaseTableCell

@property (strong, nonatomic) IBOutlet UILabel* title;
@property (strong, nonatomic) IBOutlet UILabel* summary;

+ (CGFloat)estimatedRowHeight;

@end
