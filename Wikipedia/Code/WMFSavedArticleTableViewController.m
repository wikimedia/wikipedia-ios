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

    self.fetchedResultsController = frc;
    self.tableViewUpdater = [[WMFTableViewUpdater alloc] initWithFetchedResultsController:self.fetchedResultsController tableView:self.tableView];

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
