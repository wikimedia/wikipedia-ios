//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RecentSearchesViewController.h"
#import "RecentSearchCell.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"
#import "WikipediaAppUtils.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "Wikipedia-Swift.h"
#import "UIColor+WMFHexColor.h"
#import "MWKRecentSearchList.h"
#import "MWKRecentSearchEntry.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "Defines.h"

static CGFloat const cellHeight           = 68.f;
static CGFloat const trashFontSize        = 30.f;
static NSInteger const trashColor         = 0x777777;
static NSString* const pListFileName      = @"Recent.plist";
static NSUInteger const recentSearchLimit = 100.f;

@interface RecentSearchesViewController ()

@property (strong, nonatomic) IBOutlet UITableView* table;
@property (strong, nonatomic) IBOutlet UILabel* headingLabel;
@property (strong, nonatomic) IBOutlet WikiGlyphButton* trashButton;

@end

@implementation RecentSearchesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupTrashButton];
    [self setupHeadingLabel];
    [self setupTable];

    [self updateTrashButtonEnabledState];

    [self.table setBackgroundColor:[UIColor clearColor]];
    self.table.backgroundView.backgroundColor = [UIColor clearColor];
    self.table.rowHeight                      = cellHeight;
}

- (void)setupTable {
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.table registerNib:[UINib nibWithNibName:@"RecentSearchCell" bundle:nil] forCellReuseIdentifier:@"RecentSearchCell"];
}

- (void)reloadRecentSearches {
    [self.table reloadData];
    [self updateTrashButtonEnabledState];
}

- (void)setupHeadingLabel {
    self.headingLabel.text = MWLocalizedString(@"search-recent-title", nil);
}

- (void)setupTrashButton {
    self.trashButton.backgroundColor = [UIColor clearColor];
    [self.trashButton.label setWikiText:WIKIGLYPH_TRASH color:[UIColor wmf_colorWithHex:trashColor alpha:1.0f]
                                   size:trashFontSize
                         baselineOffset:1];

    self.trashButton.accessibilityLabel  = MWLocalizedString(@"menu-trash-accessibility-label", nil);
    self.trashButton.accessibilityTraits = UIAccessibilityTraitButton;

    [self.trashButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(trashButtonTapped)]];
}

- (void)updateTrashButtonEnabledState {
    self.trashButton.enabled = ([self.recentSearches countOfEntries] > 0) ? YES : NO;
}

- (void)removeEntry:(MWKRecentSearchEntry*)entry {
    [self.recentSearches removeEntry:entry];
    [self.recentSearches save];
}

- (void)removeAllTerms {
    [self.recentSearches removeAllEntries];
    [self.recentSearches save];
}

- (void)trashButtonTapped {
    if (!self.trashButton.enabled) {
        return;
    }

    [self.trashButton animateAndRewindXF:CATransform3DMakeScale(1.2f, 1.2f, 1.0f)
                              afterDelay:0.0
                                duration:0.1
                                    then:^{
        [self showDeleteAllDialog];
    }];
}

- (void)showDeleteAllDialog {
    UIAlertView* dialog =
        [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"search-recent-clear-confirmation-heading", nil)
                                   message:MWLocalizedString(@"search-recent-clear-confirmation-sub-heading", nil)
                                  delegate:self
                         cancelButtonTitle:MWLocalizedString(@"search-recent-clear-cancel", nil)
                         otherButtonTitles:MWLocalizedString(@"search-recent-clear-delete-all", nil), nil];
    [dialog show];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.cancelButtonIndex != buttonIndex) {
        [self deleteAllRecentSearchItems];
    }
}

- (void)deleteAllRecentSearchItems {
    [self removeAllTerms];
    [self reloadRecentSearches];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.recentSearches countOfEntries];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* cellId = @"RecentSearchCell";
    RecentSearchCell* cell  = (RecentSearchCell*)[tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    NSString* term          = [[self.recentSearches entryAtIndex:indexPath.row] searchTerm];
    [cell.label setText:term];

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeEntry:[self.recentSearches entryAtIndex:indexPath.row]];

        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateTrashButtonEnabledState];
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self.delegate recentSearchController:self didSelectSearchTerm:[self.recentSearches entryAtIndex:indexPath.row]];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    [self wmf_hideKeyboard];
}

@end
