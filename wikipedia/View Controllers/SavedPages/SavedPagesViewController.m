//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SavedPagesViewController.h"
#import "WikipediaAppUtils.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "SavedPagesResultCell.h"
#import "Defines.h"
#import "Article+Convenience.h"
#import "SessionSingleton.h"
#import "CenterNavController.h"
#import "NSString+Extras.h"
#import "TopMenuContainerView.h"
#import "UIViewController+StatusBarHeight.h"
#import "UIViewController+ModalPop.h"
#import "MenuButton.h"
#import "TopMenuViewController.h"
#import "CoreDataHousekeeping.h"
#import "SavedPagesFunnel.h"
#import "NSObject+ConstraintsScale.h"
#import "PaddedLabel.h"

#define SAVED_PAGES_TITLE_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define SAVED_PAGES_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:1.0f]
#define SAVED_PAGES_LANGUAGE_COLOR [UIColor colorWithWhite:0.0f alpha:0.4f]
#define SAVED_PAGES_RESULT_HEIGHT (116.0 * MENUS_SCALE_MULTIPLIER)

@interface SavedPagesViewController ()
{
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, nonatomic) NSMutableArray *savedPagesDataArray;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) SavedPagesFunnel *funnel;

@property (strong, nonatomic) IBOutlet UIImageView *emptyImage;
@property (strong, nonatomic) IBOutlet PaddedLabel *emptyTitle;
@property (strong, nonatomic) IBOutlet PaddedLabel *emptyDescription;

@property (strong, nonatomic) IBOutlet UIView *emptyContainerView;

@end

@implementation SavedPagesViewController

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_PAGES_SAVED;
}

-(NSString *)title
{
    return MWLocalizedString(@"saved-pages-title", nil);
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Top menu

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_LABEL:
            [self popModal];

            break;
        case NAVBAR_BUTTON_TRASH:
            [self showDeleteAllDialog];
            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - View lifecycle

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];
    self.tableView.editing = NO;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    
    self.funnel = [[SavedPagesFunnel alloc] init];

    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.savedPagesDataArray = [[NSMutableArray alloc] init];
    
    [self getSavedPagesData];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0 * MENUS_SCALE_MULTIPLIER, 5.0 * MENUS_SCALE_MULTIPLIER)];
    self.tableView.tableHeaderView = headerView;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0 * MENUS_SCALE_MULTIPLIER, 10.0 * MENUS_SCALE_MULTIPLIER)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    // Register the Saved Pages results cell for reuse
    [self.tableView registerNib:[UINib nibWithNibName:@"SavedPagesResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SavedPagesResultCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self setEmptyOverlayAndTrashIconVisibility];

    [self adjustConstraintsScaleForViews:@[self.emptyImage, self.emptyTitle, self.emptyDescription, self.emptyContainerView]];
    
    self.emptyTitle.font = [UIFont boldSystemFontOfSize:17.0 * MENUS_SCALE_MULTIPLIER];
    self.emptyDescription.font = [UIFont systemFontOfSize:14.0 * MENUS_SCALE_MULTIPLIER];
}

#pragma mark - SavedPages data

-(void)getSavedPagesData
{
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Saved"
                                              inManagedObjectContext: articleDataContext_.mainContext];
    [fetchRequest setEntity:entity];
    
    // For now fetch all Saved Pages records.
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateSaved" ascending:NO selector:nil];

    [fetchRequest setSortDescriptors:@[dateSort]];

    NSMutableArray *pages = [@[] mutableCopy];

    error = nil;
    NSArray *savedPagesEntities = [articleDataContext_.mainContext executeFetchRequest:fetchRequest error:&error];
    //XCTAssert(error == nil, @"Could not fetch.");
    for (Saved *savedPage in savedPagesEntities) {
        /*
        NSLog(@"SAVED:\n\t\
              article: %@\n\t\
              date: %@\n\t\
              image: %@",
              savedPage.article.title,
              savedPage.dateSaved,
              savedPage.article.thumbnailImage.fileName
              );
        */
        [pages addObject:savedPage.objectID];
    }
    
    [self.savedPagesDataArray addObject:[@{@"data": pages} mutableCopy]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Number of rows it should expect should be based on the section
    NSDictionary *dict = self.savedPagesDataArray[section];
    NSArray *array = [dict objectForKey:@"data"];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"SavedPagesResultCell";
    SavedPagesResultCell *cell = (SavedPagesResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSDictionary *dict = self.savedPagesDataArray[indexPath.section];
    NSArray *array = [dict objectForKey:@"data"];

    __block Saved *savedEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *savedEntryId = (NSManagedObjectID *)array[indexPath.row];
        savedEntry = (Saved *)[articleDataContext_.mainContext objectWithID:savedEntryId];
    }];
    
    NSString *title = [savedEntry.article.title wikiTitleWithoutUnderscores];
    NSString *language = [NSString stringWithFormat:@"\n%@", savedEntry.article.domainName];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = [WikipediaAppUtils rtlSafeAlignment];

    NSMutableAttributedString *(^styleText)(NSString *, CGFloat, UIColor *) = ^NSMutableAttributedString *(NSString *str, CGFloat size, UIColor *color){
        return [[NSMutableAttributedString alloc] initWithString:str attributes: @{
            NSFontAttributeName : [UIFont fontWithName:@"Georgia" size:size * MENUS_SCALE_MULTIPLIER],
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : color,
        }];
    };

    NSMutableAttributedString *attributedTitle = styleText(title, 22.0, SAVED_PAGES_TEXT_COLOR);
    NSMutableAttributedString *attributedLanguage = styleText(language, 10.0, SAVED_PAGES_LANGUAGE_COLOR);
    
    [attributedTitle appendAttributedString:attributedLanguage];
    cell.textLabel.attributedText = attributedTitle;
    
    cell.methodImageView.image = nil;

    UIImage *thumbImage = [savedEntry.article getThumbnailUsingContext:articleDataContext_.mainContext];
    
    if(thumbImage){
        cell.imageView.image = thumbImage;
        cell.useField = YES;
        return cell;
    }

    // If execution reaches this point a cached core data thumb was not found.

    // Set thumbnail placeholder
//TODO: don't load thumb from file every time in loop if no image found. fix here and in search
    cell.imageView.image = [UIImage imageNamed:@"logo-placeholder-saved.png"];
    cell.useField = NO;

    //if (!thumbURL){
    //    // Don't bother downloading if no thumbURL
    //    return cell;
    //}

//TODO: retrieve a thumb
    // determine thumbURL then get thumb
    // if no thumbURL mine section html for image reference and download it

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectedCell = nil;
    NSDictionary *dict = self.savedPagesDataArray[indexPath.section];
    NSArray *array = dict[@"data"];
    selectedCell = array[indexPath.row];

    __block Saved *savedEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *savedEntryId = (NSManagedObjectID *)array[indexPath.row];
        savedEntry = (Saved *)[articleDataContext_.mainContext objectWithID:savedEntryId];
    }];
    
    [NAV loadArticleWithTitle: savedEntry.article.titleObj
                       domain: savedEntry.article.domain
                     animated: YES
              discoveryMethod: DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO
                   popToWebVC: NO];

    [self popModalToRoot];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SAVED_PAGES_RESULT_HEIGHT;
}

#pragma mark - Delete

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.tableView.editing = NO;
        [self performSelector:@selector(deleteSavedPageForIndexPath:) withObject:indexPath afterDelay:0.15f];
    }
}

-(void)deleteSavedPageForIndexPath:(NSIndexPath *)indexPath
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *savedEntryId = (NSManagedObjectID *)self.savedPagesDataArray[indexPath.section][@"data"][indexPath.row];
        Saved *savedEntry = (Saved *)[articleDataContext_.mainContext objectWithID:savedEntryId];
        if (savedEntry) {
            
            [self.tableView beginUpdates];

            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            NSError *error = nil;
            // Delete the article record. The "Saved" record will be automatically removed by
            // core data.
            [articleDataContext_.mainContext deleteObject:savedEntry.article];
            [articleDataContext_.mainContext save:&error];
            
            [self.savedPagesDataArray[indexPath.section][@"data"] removeObject:savedEntryId];
            
            [self.tableView endUpdates];

            [self setEmptyOverlayAndTrashIconVisibility];
            
            [self.funnel logDelete];
        }
    }];

    // Remove any orphaned images.
    CoreDataHousekeeping *imageHousekeeping = [[CoreDataHousekeeping alloc] init];
    [imageHousekeeping performHouseKeeping];
    
    [NAV loadTodaysArticleIfNoCoreDataForCurrentArticle];
}

-(void)deleteAllSavedPages
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        
        // Delete all entites - from: http://stackoverflow.com/a/1383645
        NSFetchRequest * savedFetch = [[NSFetchRequest alloc] init];
        [savedFetch setEntity:[NSEntityDescription entityForName:@"Saved" inManagedObjectContext:articleDataContext_.mainContext]];

        //[savedFetch setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError *error = nil;
        NSArray *savedRecords =
            [articleDataContext_.mainContext executeFetchRequest:savedFetch error:&error];
        
        // Delete the article record. The "Saved" record will be automatically removed by
        // core data.
        for (Saved *savedRecord in savedRecords) {
            [articleDataContext_.mainContext deleteObject:savedRecord.article];
            [self.funnel logDelete];
        }
        NSError *saveError = nil;
        [articleDataContext_.mainContext save:&saveError];
        
    }];

    // Remove any orphaned images.
    CoreDataHousekeeping *imageHousekeeping = [[CoreDataHousekeeping alloc] init];
    [imageHousekeeping performHouseKeeping];
    
    [self.savedPagesDataArray[0][@"data"] removeAllObjects];
    [self.tableView reloadData];
    
    [self setEmptyOverlayAndTrashIconVisibility];
    
    [NAV loadTodaysArticleIfNoCoreDataForCurrentArticle];
}

-(void)setEmptyOverlayAndTrashIconVisibility
{
    BOOL savedPageFound = ([self.savedPagesDataArray[0][@"data"] count] > 0);
    
    self.emptyOverlay.hidden = savedPageFound;

    MenuButton *trashButton = (MenuButton *)[self.topMenuViewController getNavBarItem:NAVBAR_BUTTON_TRASH];
    trashButton.alpha = savedPageFound ? 1.0 : 0.0;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex != buttonIndex) {
        [self deleteAllSavedPages];
    }
}

-(void)showDeleteAllDialog
{
    UIAlertView *dialog =
    [[UIAlertView alloc] initWithTitle: MWLocalizedString(@"saved-pages-clear-confirmation-heading", nil)
                               message: MWLocalizedString(@"saved-pages-clear-confirmation-sub-heading", nil)
                              delegate: self
                     cancelButtonTitle: MWLocalizedString(@"saved-pages-clear-cancel", nil)
                     otherButtonTitles: MWLocalizedString(@"saved-pages-clear-delete-all", nil), nil];
    [dialog show];
}

#pragma mark - Pull to refresh

- (UIScrollView *)refreshScrollView
{
    return self.tableView;
}

@end
