

@import SSDataSources;

@interface WMFMainPageTableViewCell : SSBaseTableCell

@property (nonatomic, strong) IBOutlet UILabel* mainPageTitle;

+ (CGFloat)estimatedRowHeight;

@end
