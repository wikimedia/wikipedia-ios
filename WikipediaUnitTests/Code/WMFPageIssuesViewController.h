@import UIKit;
@import WMF.Swift;

@class SSArrayDataSource;

@interface WMFPageIssuesViewController : UITableViewController <WMFThemeable>

@property (nonatomic, strong) SSArrayDataSource *dataSource;

@end
