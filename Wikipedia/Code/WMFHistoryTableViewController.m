#import "WMFHistoryTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
#import "NSUserActivity+WMFExtensions.h"

#import "NSString+WMFExtras.h"

#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "MWKHistoryList.h"

#import "MWKArticle.h"
#import "MWKSavedPageEntry.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFTableViewUpdater.h"

@interface WMFHistoryTableViewController ()
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) WMFTableViewUpdater *tableViewUpdater;
@end

@implementation WMFHistoryTableViewController

#pragma mark - NSObject

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"history-title", nil);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessors

- (MWKHistoryList *)historyList {
    return self.userDataStore.historyList;
}

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
    articleRequest.predicate = [NSPredicate predicateWithFormat:@"viewedDate != NULL"];
    articleRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"viewedDateWithoutTime" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"viewedDate" ascending:NO]];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:articleRequest managedObjectContext:self.userDataStore.viewContext sectionNameKeyPath:@"viewedDateWithoutTime" cacheName:nil];

    self.fetchedResultsController = frc;
    self.tableViewUpdater = [[WMFTableViewUpdater alloc] initWithFetchedResultsController:self.fetchedResultsController tableView:self.tableView];

    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker sharedInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_recentViewActivity]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    if ([sectionInfo numberOfObjects] == 0) {
        return @"";
    }

    NSDate *date = [[[sectionInfo objects] firstObject] viewedDateWithoutTime];

    if (!date) {
        return @"";
    }

    //HACK: Table views for some reason aren't adding padding to the left of the default headers. Injecting some manually.
    NSString *padding = @"    ";

    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    if ([calendar isDateInToday:date]) {
        return [padding stringByAppendingString:[MWLocalizedString(@"history-section-today", nil) uppercaseString]];
    } else if ([calendar isDateInYesterday:date]) {
        return [padding stringByAppendingString:[MWLocalizedString(@"history-section-yesterday", nil) uppercaseString]];
    } else {
        return [padding stringByAppendingString:[[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:date]];
    }
}

- (void)configureCell:(WMFArticleListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticle *entry = [self objectAtIndexPath:indexPath];
    MWKArticle *article = [[self userDataStore] articleWithURL:entry.URL];
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
    [[self historyList] removeEntryWithURL:[self urlAtIndexPath:indexPath]];
}

#pragma mark - WMFArticleListTableViewController

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNoHistory;
}

- (NSString *)analyticsContext {
    return @"Recent";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

- (BOOL)showsDeleteAllButton {
    return YES;
}

- (NSString *)deleteButtonText {
    return MWLocalizedString(@"history-clear-all", nil);
}

- (NSString *)deleteAllConfirmationText {
    return MWLocalizedString(@"history-clear-confirmation-heading", nil);
}

- (NSString *)deleteText {
    return MWLocalizedString(@"history-clear-delete-all", nil);
}

- (NSString *)deleteCancelText {
    return MWLocalizedString(@"history-clear-cancel", nil);
}

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectAtIndexPath:indexPath] URL];
}

- (void)deleteAll {
    [[self historyList] removeAllEntries];
}

- (BOOL)isEmpty {
    return self.fetchedResultsController.sections.count == 0;
}

@end
