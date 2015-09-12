
#import <SSDataSources/SSDataSources.h>

@interface WMFHomeSectionFooter : SSBaseCollectionReusableView

@property (strong, nonatomic) IBOutlet UILabel* moreLabel;
@property (strong, nonatomic) IBOutlet UIView* backgroundView;
@property (copy, nonatomic) dispatch_block_t whenTapped;

@end
