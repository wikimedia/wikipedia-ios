#import "WMFSavedArticleTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
#import "NSString+WMFExtras.h"
#import "NSUserActivity+WMFExtensions.h"

#import "MWKDataStore.h"

#import "MWKSavedPageList.h"

#import "MWKArticle.h"

#import "WMFSaveButtonController.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFTableViewUpdater.h"

@interface WMFSavedArticleTableViewController ()
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) WMFTableViewUpdater *tableViewUpdater;
@end

@implementation WMFSavedArticleTableViewController

#pragma mark - NSObject

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = WMFLocalizedStringWithDefaultValue(@"saved-title", nil, nil, @"Saved", @"Title of the saved screen shown on the saved tab\n{{Identical|Saved}}");
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

    self.fetchedResultsController = frc;
    self.tableViewUpdater = [[WMFTableViewUpdater alloc] initWithFetchedResultsController:self.fetchedResultsController tableView:self.tableView];
    self.tableViewUpdater.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
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
    cell.titleText = entry.displayTitle;
    cell.descriptionText = [entry.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImageURL:entry.thumbnailURL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
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
    return WMFLocalizedStringWithDefaultValue(@"saved-clear-all", nil, nil, @"Clear", @"Text of the button shown at the top of saved pages which deletes all the saved pages\n{{Identical|Clear}}");
}

- (NSString *)deleteAllConfirmationText {
    return WMFLocalizedStringWithDefaultValue(@"saved-pages-clear-confirmation-heading", nil, nil, @"Are you sure you want to delete all your saved pages?", @"Heading text of delete all confirmation dialog");
}

- (NSString *)deleteText {
    return WMFLocalizedStringWithDefaultValue(@"saved-pages-clear-delete-all", nil, nil, @"Yes, delete all", @"Button text for confirming delete all action\n{{Identical|Delete all}}");
}

- (NSString *)deleteCancelText {
    return WMFLocalizedStringWithDefaultValue(@"saved-pages-clear-cancel", nil, nil, @"Cancel", @"Button text for cancelling delete all action\n{{Identical|Cancel}}");
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectAtIndexPath:indexPath] URL];
}

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)deleteItemAtIndexPath:(NSIndexPath*)indexPath{
    [[self savedPageList] removeEntryWithURL:[self urlAtIndexPath:indexPath]];
}

- (void)deleteAll {
    [[self savedPageList] removeAllEntries];
}

- (BOOL)isEmpty {
    return [self tableView:self.tableView numberOfRowsInSection:0] == 0;
}

@end
