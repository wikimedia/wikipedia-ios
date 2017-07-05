@import UIKit;
@import WMF.Swift;

@interface WMFExploreSectionFooter : UICollectionReusableView <WMFThemeable>

@property (strong, nonatomic) IBOutlet UILabel *moreLabel;
@property (strong, nonatomic) IBOutlet UIView *visibleBackgroundView;
@property (copy, nonatomic) dispatch_block_t whenTapped;

@end
