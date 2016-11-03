#import "WMFSavedArticleTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
#import "NSString+WMFExtras.h"
#import "NSUserActivity+WMFExtensions.h"

#import "MWKDataStore.h"

#import "MWKSavedPageList.h"

#import "MWKDataStore+WMFDataSources.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"

#import "MWKArticle.h"
#import "MWKHistoryEntry.h"

#import "WMFSaveButtonController.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

@interface WMFSavedArticleTableViewController () <WMFDataSourceDelegate>

@property (nonatomic, strong) id<WMFDataSource> dataSource;

@end

@implementation WMFSavedArticleTableViewController

#pragma mark - NSObject

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"saved-title", nil);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessors

- (MWKSavedPageList *)savedPageList {
    return self.userDataStore.savedPageList;
}

- (MWKHistoryEntry*)objectAtIndexPath:(NSIndexPath*)indexPath{
    return (MWKHistoryEntry*)[self.dataSource objectAtIndexPath:indexPath];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
    self.tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(teardownNotification:) name:MWKTeardownDataSourcesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupNotification:) name:MWKSetupDataSourcesNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupDataSource];
}

- (void)setupDataSource {
    self.dataSource = [self.userDataStore savedDataSource];
    self.dataSource.granularDelegateCallbacksEnabled = YES;
    self.dataSource.delegate = self;
    [self.tableView reloadData];
    [self updateEmptyAndDeleteState];
}

- (void)teardownDataSource {
    self.dataSource.delegate = nil;
    self.dataSource = nil;
}

- (void)teardownNotification:(NSNotification *)note {
    [self teardownDataSource];
}

- (void)setupNotification:(NSNotification *)note {
    [self setupDataSource];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker sharedInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_savedPagesViewActivity]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self teardownDataSource];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataSource numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];

    MWKHistoryEntry *entry = [self objectAtIndexPath:indexPath];
    MWKArticle *article = [self.userDataStore articleWithURL:entry.url];
    cell.titleText = article.url.wmf_title;
    cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImage:[article bestThumbnailImage]];

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self savedPageList] removeEntryWithURL:[self urlAtIndexPath:indexPath]];
}

#pragma mark - WMFDataSourceDelegate

- (void)dataSourceDidUpdateAllData:(id<WMFDataSource>)dataSource {
    [self.tableView reloadData];
}

- (void)dataSourceWillBeginUpdates:(id<WMFDataSource>)dataSource {
    [self.tableView beginUpdates];
}

- (void)dataSourceDidFinishUpdates:(id<WMFDataSource>)dataSource {
    [self.tableView endUpdates];
    [self updateEmptyAndDeleteState];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didDeleteSectionsAtIndexes:(NSIndexSet *)indexes {
    [self.tableView deleteSections:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didInsertSectionsAtIndexes:(NSIndexSet *)indexes {
    [self.tableView insertSections:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didDeleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didInsertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didMoveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self.tableView deleteRowsAtIndexPaths:@[fromIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView insertRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didUpdateRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
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
    return [[self objectAtIndexPath:indexPath] url];
}

- (void)deleteAll {
    [[self savedPageList] removeAllEntries];
}

- (NSInteger)numberOfItems {
    return [self.dataSource numberOfItems];
}

@end
