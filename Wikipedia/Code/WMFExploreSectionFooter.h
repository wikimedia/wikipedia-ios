#import "WMFExploreCollectionViewCell.h"
@import WMF.Swift;

@interface WMFExploreSectionFooter : WMFExploreCollectionReusableView <WMFThemeable>

@property (strong, nonatomic) IBOutlet UILabel *moreLabel;
@property (strong, nonatomic) IBOutlet UIView *visibleBackgroundView;
@property (copy, nonatomic) dispatch_block_t whenTapped;

@end
