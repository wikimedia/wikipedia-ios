#import "RecentSearchesViewController.h"
@import WMF.MWKRecentSearchList;
@import WMF.MWKRecentSearchEntry;
@import Masonry;
#import "UIButton+WMFButton.h"
#import "Wikipedia-Swift.h"

static NSString *const pListFileName = @"Recent.plist";
static NSString *const RecentSearchesViewControllerCellIdentifier = @"RecentSearchCell";

@interface RecentSearchesViewController ()

@property (strong, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) IBOutlet UILabel *headingLabel;
@property (strong, nonatomic) IBOutlet UIView *headerContainer;
@property (strong, nonatomic) IBOutlet UIView *trashButtonContainer;
@property (strong, nonatomic) UIButton *trashButton;
@property (strong, nonatomic) WMFTheme *theme;

@end

@implementation RecentSearchesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupTrashButton];
    [self setupHeadingLabel];
    [self setupTable];

    [self updateTrashButtonEnabledState];
    [self updateHeaderVisibility];
    [self.view wmf_configureSubviewsForDynamicType];

    [self applyTheme:self.theme];
}

- (void)setupTable {
    [self.table registerClass:[WMFArticleListTableViewCell class] forCellReuseIdentifier:RecentSearchesViewControllerCellIdentifier];

    self.table.estimatedRowHeight = 52.f;
    self.table.rowHeight = UITableViewAutomaticDimension;
}

- (void)reloadRecentSearches {
    [self.table reloadData];
    [self updateTrashButtonEnabledState];
    [self updateHeaderVisibility];
}

- (void)setupHeadingLabel {
    // Reminder: TWN has in the past rejected all-caps strings because there are complications
    // with translation/meaning of all-caps in other languages. The recommendation
    // was to submit strings to TWN with non-all-caps, and at display time force the string
    // to all caps.
    self.headingLabel.text = [WMFLocalizedStringWithDefaultValue(@"search-recent-title", nil, nil, @"Recently searched", @"Title for list of recent search terms") uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (void)setupTrashButton {
    self.trashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.trashButton setImage:[UIImage imageNamed:@"clear-mini"] forState:UIControlStateNormal];
    [self.trashButton addTarget:self action:@selector(showDeleteAllDialog) forControlEvents:UIControlEventTouchUpInside];
    [self.trashButtonContainer addSubview:self.trashButton];

    [self.trashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.and.bottom.equalTo(self.trashButtonContainer);
    }];

    self.trashButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"menu-trash-accessibility-label", nil, nil, @"Delete", @"Accessible label for trash button\n{{Identical|Delete}}");
    self.trashButton.accessibilityTraits = UIAccessibilityTraitButton;
}

- (void)updateTrashButtonEnabledState {
    self.trashButton.enabled = ([self.recentSearches countOfEntries] > 0) ? YES : NO;
}

- (void)updateHeaderVisibility {
    self.headerContainer.hidden = ([self.recentSearches countOfEntries] > 0) ? NO : YES;
}

- (void)removeEntry:(MWKRecentSearchEntry *)entry {
    [self.recentSearches removeEntry:entry];
    [self.recentSearches save];
}

- (void)removeAllTerms {
    [self.recentSearches removeAllEntries];
    [self.recentSearches save];
}

- (void)showDeleteAllDialog {
    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-confirmation-heading", nil, nil, @"Delete all recent searches?", @"Heading text of delete all confirmation dialog") message:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-confirmation-sub-heading", nil, nil, @"This action cannot be undone!", @"Sub-heading text of delete all confirmation dialog") preferredStyle:UIAlertControllerStyleAlert];

    [dialog addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-cancel", nil, nil, @"Cancel", @"Button text for cancelling delete all action\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];

    [dialog addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-delete-all", nil, nil, @"Delete All", @"Button text for confirming delete all action\n{{Identical|Delete all}}")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull action) {
                                                 [self deleteAllRecentSearchItems];
                                             }]];

    [self presentViewController:dialog animated:YES completion:NULL];
}

- (void)deleteAllRecentSearchItems {
    [self removeAllTerms];
    [self reloadRecentSearches];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.recentSearches countOfEntries];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = (WMFArticleListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:RecentSearchesViewControllerCellIdentifier forIndexPath:indexPath];
    [cell applyTheme:self.theme];
    cell.articleCell.isImageViewHidden = YES;
    NSString *term = [[self.recentSearches entryAtIndex:indexPath.row] searchTerm];
    [cell setTitleText:term];

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [self removeEntry:[self.recentSearches entryAtIndex:indexPath.row]];
//
//        // Delete the row from the data source
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        [self updateTrashButtonEnabledState];
//        [self updateHeaderVisibility];
//    }
//}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [self deleteAction:indexPath];
    deleteAction.backgroundColor = self.theme.colors.destructive;
    
    UITableViewRowAction *shareAction = [self shareAction:indexPath];
    shareAction.backgroundColor = self.theme.colors.secondaryAction;
    
    NSMutableArray<UITableViewRowAction *> *actions = [[NSMutableArray alloc] initWithObjects:deleteAction, shareAction, nil];
    
    return actions;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate recentSearchController:self didSelectSearchTerm:[self.recentSearches entryAtIndex:indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

#pragma mark - Row actions

- (UITableViewRowAction *)rowActionWithStyle:(UITableViewRowActionStyle)style title:(nullable NSString *)title handler:(void (^)(UITableViewRowAction *action, NSIndexPath *indexPath))handler {
    return [UITableViewRowAction rowActionWithStyle:style
                                              title:title
                                            handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                [CATransaction begin];
                                                [CATransaction setCompletionBlock:^{
                                                    if (handler) {
                                                        handler(action, indexPath);
                                                    }
                                                }];
                                                [self.table setEditing:NO animated:YES];
                                                [CATransaction commit];
                                            }];
}

- (NSString *)deleteActionText {
    return WMFLocalizedStringWithDefaultValue(@"recent-search-delete", nil, nil, @"Delete", @"Text of the recent search list row action shown on swipe which deletes the article");
}

- (UITableViewRowAction *)deleteAction:(NSIndexPath *)indexPath {
    return [self rowActionWithStyle:UITableViewRowActionStyleDestructive
                              title:[self deleteActionText]
                            handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                [self removeEntry:[self.recentSearches entryAtIndex:indexPath.row]];
                                
                                // Delete the row from the data source
                                [self.table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                [self updateTrashButtonEnabledState];
                                [self updateHeaderVisibility];
                            }];
}

- (NSString *)shareActionText {
    return WMFLocalizedStringWithDefaultValue(@"recent-search-share", nil, nil, @"Share", @"Text of the recent search list row action shown on swipe which allows the user to choose the sharing option");
}

- (UITableViewRowAction *)shareAction:(NSIndexPath *)indexPath {
    return [self rowActionWithStyle:UITableViewRowActionStyleNormal
                              title:[self shareActionText]
                            handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
//                                NSURL *url = [self urlAtIndexPath:indexPath];
//                                
//                                [self shareArticle:url];
                            }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self wmf_hideKeyboard];
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }

    self.table.backgroundColor = theme.colors.midBackground;
    self.table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.table.separatorColor = theme.colors.border;

    self.headerContainer.backgroundColor = theme.colors.midBackground;
    self.headingLabel.textColor = theme.colors.secondaryText;

    self.trashButton.tintColor = theme.colors.secondaryText;

    [self.table reloadData];
}

@end
