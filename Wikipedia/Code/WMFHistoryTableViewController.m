#import "WMFHistoryTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
#import "NSUserActivity+WMFExtensions.h"

#import "NSString+WMFExtras.h"
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
    self.title = WMFLocalizedStringWithDefaultValue(@"history-title", nil, nil, @"History", @"Title of the history screen shown on history tab\n{{Identical|History}}");
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
    self.tableViewUpdater.delegate = self;

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
        return [padding stringByAppendingString:[WMFLocalizedStringWithDefaultValue(@"history-section-today", nil, nil, @"Today", @"Subsection label for list of articles browsed today.\n{{Identical|Today}}") uppercaseString]];
    } else if ([calendar isDateInYesterday:date]) {
        return [padding stringByAppendingString:[WMFLocalizedStringWithDefaultValue(@"history-section-yesterday", nil, nil, @"Yesterday", @"Subsection label for list of articles browsed yesterday.\n{{Identical|Yesterday}}") uppercaseString]];
    } else {
        return [padding stringByAppendingString:[[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:date]];
    }
}

- (void)configureCell:(WMFArticleListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticle *entry = [self objectAtIndexPath:indexPath];
    cell.titleText = entry.displayTitle;
    cell.descriptionText = [entry.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImageURL:entry.thumbnailURL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];

    [self configureCell:cell forRowAtIndexPath:indexPath];

    return cell;
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
    return WMFLocalizedStringWithDefaultValue(@"history-clear-all", nil, nil, @"Clear", @"Text of the button shown at the top of history which deletes all history\n{{Identical|Clear}}");
}

- (NSString *)deleteAllConfirmationText {
    return WMFLocalizedStringWithDefaultValue(@"history-clear-confirmation-heading", nil, nil, @"Are you sure you want to delete all your recent items?", @"Heading text of delete all confirmation dialog");
}

- (NSString *)deleteText {
    return WMFLocalizedStringWithDefaultValue(@"history-clear-delete-all", nil, nil, @"Yes, delete all", @"Button text for confirming delete all action");
}

- (NSString *)deleteCancelText {
    return WMFLocalizedStringWithDefaultValue(@"history-clear-cancel", nil, nil, @"Cancel", @"Button text for cancelling delete all action\n{{Identical|Cancel}}");
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectAtIndexPath:indexPath] URL];
}

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)deleteItemAtIndexPath:(NSIndexPath*)indexPath{
    [[self historyList] removeEntryWithURL:[self urlAtIndexPath:indexPath]];
}

- (void)deleteAll {
    [[self historyList] removeAllEntries];
}

- (BOOL)isEmpty {
    return self.fetchedResultsController.sections.count == 0;
}

@end
