
#import <SSDataSources/SSDataSources.h>

@class WMFTitleInsetRespectingButton;

@interface WMFArticlePlaceholderCollectionViewCell : SSBaseCollectionCell

@property (strong, nonatomic) IBOutlet UIImageView* placeholderImageView;
@property (strong, nonatomic) IBOutlet WMFTitleInsetRespectingButton* placeholderSaveButton;

@end
