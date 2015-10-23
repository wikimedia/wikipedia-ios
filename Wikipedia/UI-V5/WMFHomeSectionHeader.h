
#import <SSDataSources/SSDataSources.h>

@interface WMFHomeSectionHeader : SSBaseCollectionReusableView

@property (strong, nonatomic) IBOutlet UIImageView* icon;
@property (strong, nonatomic) IBOutlet UITextView* titleView;
@property (strong, nonatomic) IBOutlet UIButton* rightButton;

@property (assign, nonatomic) BOOL rightButtonEnabled;

@end
