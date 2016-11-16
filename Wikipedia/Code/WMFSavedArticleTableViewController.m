#import "WMFSavedArticleTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
#import "NSString+WMFExtras.h"
#import "NSUserActivity+WMFExtensions.h"

#import "MWKDataStore.h"

#import "MWKSavedPageList.h"

#import "MWKDataStore+WMFDataSources.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"

#import "MWKArticle.h"

#import "WMFSaveButtonController.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

@interface WMFSavedArticleTableViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation WMFSavedArticleTableViewController

#pragma mark - NSObject

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"saved-title", nil);
}

- (void)dealloc {
}

#pragma mark - Accessors

- (MWKSavedPageList *)savedPageList {
    return self.userDataStore.savedPageList;
}

- (WMFArticle *)objectAtIndexPath:(NSIndexPath *)indexPath {
    return (WMFArticle *)[self.fetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
    self.tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];

    NSFetchRequest *articleRequest = [WMFArticle fetchRequest];
    articleRequest.predicate = [NSPredicate predicateWithFormat:@"savedDate != NULL"];
    articleRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"savedDate" ascending:NO]];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:articleRequest managedObjectContext:self.userDataStore.viewContext sectionNameKeyPath:nil cacheName:nil];
    frc.delegate = self;
    [frc performFetch:nil];
    self.fetchedResultsController = frc;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker sharedInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_savedPagesViewActivity]];
}
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray<id<NSFetchedResultsSectionInfo>> *sections = self.fetchedResultsController.sections;
    if (section >= sections.count) {
        return 0;
    }
    return [sections[section] numberOfObjects];
}

- (void)configureCell:(WMFArticleListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticle *entry = [self objectAtIndexPath:indexPath];
    MWKArticle *article = [self.userDataStore articleWithURL:entry.URL];
    cell.titleText = article.url.wmf_title;
    cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImage:[article bestThumbnailImage]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self savedPageList] removeEntryWithURL:[self urlAtIndexPath:indexPath]];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] forRowAtIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNoSavedPages;
}

- (NSString *)analyticsContext {
    return @"Saved";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

- (BOOL)showsDeleteAllButton {
    return YES;
}

- (NSString *)deleteButtonText {
    return MWLocalizedString(@"saved-clear-all", nil);
}

- (NSString *)deleteAllConfirmationText {
    return MWLocalizedString(@"saved-pages-clear-confirmation-heading", nil);
}

- (NSString *)deleteText {
    return MWLocalizedString(@"saved-pages-clear-delete-all", nil);
}

- (NSString *)deleteCancelText {
    return MWLocalizedString(@"saved-pages-clear-cancel", nil);
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectAtIndexPath:indexPath] URL];
}

- (void)deleteAll {
    [[self savedPageList] removeAllEntries];
}

- (BOOL)isEmpty {
    return [self tableView:self.tableView numberOfRowsInSection:0] == 0;
}

@end
