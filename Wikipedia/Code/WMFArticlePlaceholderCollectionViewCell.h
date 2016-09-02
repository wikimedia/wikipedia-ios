#import "WMFExploreCollectionViewCell.h"

@class WMFTitleInsetRespectingButton;

@interface WMFArticlePlaceholderCollectionViewCell : WMFExploreCollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *placeholderImageView;
@property (strong, nonatomic) IBOutlet WMFTitleInsetRespectingButton *placeholderSaveButton;

@end
