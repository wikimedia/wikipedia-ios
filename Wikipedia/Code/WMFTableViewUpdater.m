#import "WMFTableViewUpdater.h"
#import "WMFChange.h"

@interface WMFTableViewUpdater () <NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray<WMFSectionChange *> *sectionChanges;
@property (nonatomic, strong) NSMutableArray<WMFObjectChange *> *objectChanges;
@end

@implementation WMFTableViewUpdater

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController tableView:(UITableView *)tableView {
    self = [super init];
    if (self) {
        self.tableView = tableView;
        self.fetchedResultsController = fetchedResultsController;
        self.fetchedResultsController.delegate = self;
        self.sectionChanges = [NSMutableArray arrayWithCapacity:10];
        self.objectChanges = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    WMFSectionChange *sectionChange = [WMFSectionChange new];
    sectionChange.type = type;
    sectionChange.sectionIndex = sectionIndex;
    [self.sectionChanges addObject:sectionChange];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    WMFObjectChange *objectChange = [WMFObjectChange new];
    objectChange.type = type;
    objectChange.fromIndexPath = indexPath;
    objectChange.toIndexPath = newIndexPath;
    [self.objectChanges addObject:objectChange];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
    for (WMFSectionChange *change in self.sectionChanges) {
        switch (change.type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:change.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:change.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:change.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            case NSFetchedResultsChangeMove:
                break;
        }
    }
    for (WMFObjectChange *change in self.objectChanges) {
        switch (change.type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertRowsAtIndexPaths:@[change.toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteRowsAtIndexPaths:@[change.fromIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            case NSFetchedResultsChangeUpdate:
                if (change.fromIndexPath && [change.toIndexPath isEqual:change.fromIndexPath]) {
                    [self.tableView reloadRowsAtIndexPaths:@[change.toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                } else if (change.toIndexPath && change.fromIndexPath) {
                    [self.tableView moveRowAtIndexPath:change.fromIndexPath toIndexPath:change.toIndexPath];
                } else if (change.toIndexPath) {
                    [self.tableView reloadRowsAtIndexPaths:@[change.toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                } else if (change.fromIndexPath) {
                    [self.tableView reloadRowsAtIndexPaths:@[change.fromIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                break;
            case NSFetchedResultsChangeMove:
                [self.tableView moveRowAtIndexPath:change.fromIndexPath toIndexPath:change.toIndexPath];
                break;
        }
    }
    [self.tableView endUpdates];

    [self.objectChanges removeAllObjects];
    [self.sectionChanges removeAllObjects];
}

@end
