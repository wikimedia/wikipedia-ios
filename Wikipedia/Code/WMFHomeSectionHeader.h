
@import UIKit;

@interface WMFHomeSectionHeader : UITableViewHeaderFooterView

@property (strong, nonatomic) IBOutlet UIImageView* icon;
@property (strong, nonatomic) IBOutlet UILabel* titleView;
@property (strong, nonatomic) IBOutlet UIButton* rightButton;

@property (assign, nonatomic) BOOL rightButtonEnabled;
@property (copy, nonatomic) dispatch_block_t whenTapped;

@end
