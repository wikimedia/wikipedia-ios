#import <Foundation/Foundation.h>

@class WMFTableViewUpdater;

@protocol  WMFTableViewUpdaterDelegate <NSObject>
@required
- (void)tableViewUpdater:(WMFTableViewUpdater *)updater didUpdateTableView:(UITableView *)tableView;
@end

@interface WMFTableViewUpdater : NSObject

@property (nonatomic, assign) id <WMFTableViewUpdaterDelegate> delegate;

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController tableView:(UITableView *)tableView NS_DESIGNATED_INITIALIZER;

@end
