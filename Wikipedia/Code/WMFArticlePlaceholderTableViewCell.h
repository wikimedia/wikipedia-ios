#import "SSDataSources.h"

@class WMFTitleInsetRespectingButton;

@interface WMFArticlePlaceholderTableViewCell : SSBaseTableCell

@property (strong, nonatomic) IBOutlet UIImageView *placeholderImageView;
@property (strong, nonatomic) IBOutlet WMFTitleInsetRespectingButton *placeholderSaveButton;

@end
