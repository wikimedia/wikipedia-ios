@import UIKit;

@interface WMFExploreSectionHeader : UICollectionReusableView

- (void)setImage:(UIImage *)image;
- (void)setImageTintColor:(UIColor *)imageTintColor;
- (void)setImageBackgroundColor:(UIColor *)imageBackgroundColor;

- (void)setTitle:(NSString *)title;
- (void)setSubTitle:(NSString *)subTitle;

- (void)setTitleColor:(UIColor *)titleColor;
- (void)setSubTitleColor:(UIColor *)subTitleColor;

@property (strong, nonatomic) IBOutlet UIButton *rightButton;

@property (assign, nonatomic) BOOL rightButtonEnabled;
@property (copy, nonatomic) dispatch_block_t whenTapped;

@end
