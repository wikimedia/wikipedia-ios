//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RecentSearchesViewController.h"
#import "RecentSearchCell.h"
#import "PaddedLabel.h"
#import "NSObject+ConstraintsScale.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"
#import "WikipediaAppUtils.h"
#import "NSArray+Predicate.h"
#import "TopMenuTextFieldContainer.h"
#import "TopMenuTextField.h"
#import "TopMenuViewController.h"
#import "RootViewController.h"
#import "UIViewController+HideKeyboard.h"

#define CELL_HEIGHT (48.0 * MENUS_SCALE_MULTIPLIER)
#define HEADING_FONT_SIZE (16.0 * MENUS_SCALE_MULTIPLIER)
#define HEADING_COLOR [UIColor blackColor]
#define HEADING_PADDING UIEdgeInsetsMake(22.0f, 16.0f, 22.0f, 16.0f)
#define TRASH_FONT_SIZE (30.0 * MENUS_SCALE_MULTIPLIER)
#define TRASH_COLOR [UIColor grayColor]
#define TRASH_DISABLED_COLOR [UIColor lightGrayColor]
#define PLIST_FILE_NAME @"Recent.plist"

@interface RecentSearchesViewController ()

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet PaddedLabel *headingLabel;
@property (weak, nonatomic) IBOutlet WikiGlyphButton *trashButton;

@property (strong, nonatomic) NSMutableArray *tableDataArray;
@property (strong, nonatomic) NSNumber *recentSearchesItemCount;

@end

@implementation RecentSearchesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableDataArray = @[].mutableCopy;
    
    [self setupTrashButton];
    [self setupHeadingLabel];
    [self setupTable];

    [self loadDataArrayFromFile];
    
    [self adjustConstraintsScaleForViews:@[self.headingLabel, self.trashButton]];
    
    [self updateTrashButtonEnabledState];

    self.recentSearchesItemCount = @(self.tableDataArray.count);
}

-(void)setupTable
{
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self.table registerNib:[UINib nibWithNibName:@"RecentSearchCell" bundle:nil] forCellReuseIdentifier:@"RecentSearchCell"];
}

-(void)setupHeadingLabel
{
    self.headingLabel.padding = HEADING_PADDING;
    self.headingLabel.font = [UIFont boldSystemFontOfSize:HEADING_FONT_SIZE];
    self.headingLabel.textColor = HEADING_COLOR;
    self.headingLabel.text = MWLocalizedString(@"search-recent-title", nil);
}

-(void)setupTrashButton
{
    self.trashButton.backgroundColor = [UIColor clearColor];
    [self.trashButton.label setWikiText: WIKIGLYPH_TRASH color:TRASH_COLOR
                                   size: TRASH_FONT_SIZE
                         baselineOffset: 0];
    
    self.trashButton.accessibilityLabel = MWLocalizedString(@"menu-trash-accessibility-label", nil);
    self.trashButton.accessibilityTraits = UIAccessibilityTraitButton;
    
    [self.trashButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                   action: @selector(showDeleteAllDialog)]];
}

-(void)saveTerm: (NSString *)term
      forDomain: (NSString *)domain
           type: (SearchType)searchType
{
    if (!term || (term.length == 0)) return;
    if (!domain || (domain.length == 0)) return;

    NSDictionary *termDict = [self dataForTerm:term domain:domain];
    if (termDict){
        [self removeTerm:term forDomain:domain];
    }

    [self.tableDataArray insertObject:@{
                                        @"term": term,
                                        @"domain": domain,
                                        @"timestamp": [NSDate date],
                                        @"type": @(searchType)
                                        } atIndex:0];
    
    [self saveDataArrayToFile];
    [self.table reloadData];
}

-(void)updateTrashButtonEnabledState
{
    self.trashButton.enabled = (self.tableDataArray.count > 0) ? YES : NO;
}

-(void)removeTerm: (NSString *)term
        forDomain: (NSString *)domain
{
    NSDictionary *termDict = [self dataForTerm:term domain:domain];
    if (termDict){
        [self.tableDataArray removeObject:termDict];
        [self saveDataArrayToFile];
    }
}

-(void)removeAllTerms
{
    [self.tableDataArray removeAllObjects];
    [self saveDataArrayToFile];
}

-(NSDictionary *)dataForTerm: (NSString *)term
                      domain: (NSString *)domain
{
    // For now just match on the search term, not the domain or other fields.
    return [self.tableDataArray firstMatchForPredicate:[NSPredicate predicateWithFormat:@"(term == %@)", term]];
    //return [self.tableDataArray firstMatchForPredicate:[NSPredicate predicateWithFormat:@"(term == %@) AND (domain == %@)", term, domain]];
}

-(NSString *)getFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return  [documentsDirectory stringByAppendingPathComponent:PLIST_FILE_NAME];
}

-(void)saveDataArrayToFile
{
    NSError *error;
    NSString *path = [self getFilePath];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager isDeletableFileAtPath:path]) {
        [manager removeItemAtPath:path error:&error];
    }

    if (![manager fileExistsAtPath:path]) {
        [self.tableDataArray writeToFile:path atomically:YES];
    }
    
    [self updateTrashButtonEnabledState];
    
    self.recentSearchesItemCount = @(self.tableDataArray.count);
}

-(void)loadDataArrayFromFile
{
    NSString *path = [self getFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSArray *a = [[NSArray alloc] initWithContentsOfFile:path];
        self.tableDataArray = a.mutableCopy;
    }
}

-(void)showDeleteAllDialog
{
    if(!self.trashButton.enabled) return;

    UIAlertView *dialog =
    [[UIAlertView alloc] initWithTitle: MWLocalizedString(@"search-recent-clear-confirmation-heading", nil)
                               message: MWLocalizedString(@"search-recent-clear-confirmation-sub-heading", nil)
                              delegate: self
                     cancelButtonTitle: MWLocalizedString(@"search-recent-clear-cancel", nil)
                     otherButtonTitles: MWLocalizedString(@"search-recent-clear-delete-all", nil), nil];
    [dialog show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex != buttonIndex) {
        [self deleteAllRecentSearchItems];
    }
}

-(void)deleteAllRecentSearchItems
{
    [self removeAllTerms];
    [self.table reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.tableDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"RecentSearchCell";
    RecentSearchCell *cell = (RecentSearchCell *)[tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    NSString *term = self.tableDataArray[indexPath.row][@"term"];
    [cell.label setText:term];
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        NSString *term = self.tableDataArray[indexPath.row][@"term"];
        NSString *domain = self.tableDataArray[indexPath.row][@"domain"];
        [self removeTerm:term forDomain:domain];
    
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopMenuTextFieldContainer *textFieldContainer =
        [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
    NSString *term = self.tableDataArray[indexPath.row][@"term"];
    textFieldContainer.textField.text = term;
    [textFieldContainer.textField sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideKeyboard];
}

@end
