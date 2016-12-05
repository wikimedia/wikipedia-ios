#import <Foundation/Foundation.h>

@interface WMFTableViewUpdater : NSObject

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController tableView:(UITableView *)tableView NS_DESIGNATED_INITIALIZER;

@end
