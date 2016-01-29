
@import UIKit;

@interface WMFExploreSectionHeader : UITableViewHeaderFooterView

@property (strong, nonatomic) UIImage* image;
@property (strong, nonatomic) UIColor* imageTintColor;
@property (strong, nonatomic) UIColor* imageBackgroundColor;

@property (strong, nonatomic) NSAttributedString* title;
@property (strong, nonatomic) NSAttributedString* subTitle;

@property (strong, nonatomic) IBOutlet UIButton* rightButton;

@property (assign, nonatomic) BOOL rightButtonEnabled;
@property (copy, nonatomic) dispatch_block_t whenTapped;

@end
