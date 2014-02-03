//  Created by Monte Hurd on 12/16/13.

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"

@class WebViewController;

@interface SearchResultsController : UIViewController <UITableViewDelegate, NetworkOpDelegate>

@property (weak, nonatomic) IBOutlet UITableView *searchResultsTable;
@property (strong, atomic) NSMutableArray *searchResultsOrdered;
@property (weak, nonatomic) WebViewController *webViewController;

@end
