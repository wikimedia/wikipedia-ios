//  Created by Monte Hurd on 12/4/13.

#import "SavedPagesViewController.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "SavedPagesResultCell.h"
#import "SavedPagesTableHeadingLabel.h"
#import "Defines.h"
#import "Article+Convenience.h"
#import "SessionSingleton.h"
#import "UINavigationController+SearchNavStack.h"
#import "NavController.h"

#define NAV ((NavController *)self.navigationController)

#define SAVED_PAGES_TITLE_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define SAVED_PAGES_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:1.0f]
#define SAVED_PAGES_LANGUAGE_COLOR [UIColor colorWithWhite:0.0f alpha:0.4f]
#define SAVED_PAGES_RESULT_HEIGHT 116

@interface SavedPagesViewController ()
{
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, atomic) NSMutableArray *savedPagesDataArray;

@end

@implementation SavedPagesViewController

#pragma mark - Init

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.savedPagesDataArray = [[NSMutableArray alloc] init];
    
    [self getSavedPagesData];

    SavedPagesTableHeadingLabel *savedPagesLabel = [[SavedPagesTableHeadingLabel alloc] initWithFrame:CGRectMake(0, 0, 10, 53)];
    savedPagesLabel.text = NSLocalizedString(@"saved-pages-title", nil);
    savedPagesLabel.textAlignment = NSTextAlignmentCenter;
    savedPagesLabel.font = [UIFont boldSystemFontOfSize:20.0];
    savedPagesLabel.textColor = SAVED_PAGES_TITLE_TEXT_COLOR;
    self.tableView.tableHeaderView = savedPagesLabel;
    savedPagesLabel.backgroundColor = [UIColor whiteColor];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    // Register the Saved Pages results cell for reuse
    [self.tableView registerNib:[UINib nibWithNibName:@"SavedPagesResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SavedPagesResultCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
    
    NSString *title = [savedEntry.article.title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    NSString *language = [NSString stringWithFormat:@"\n%@", savedEntry.article.domainName];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;

    NSMutableAttributedString *(^styleText)(NSString *, CGFloat, UIColor *) = ^NSMutableAttributedString *(NSString *str, CGFloat size, UIColor *color){
        return [[NSMutableAttributedString alloc] initWithString:str attributes: @{
            NSFontAttributeName : [UIFont fontWithName:@"Georgia" size:size],
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : color,
        }];
    };

    NSMutableAttributedString *attributedTitle = styleText(title, 22, SAVED_PAGES_TEXT_COLOR);
    NSMutableAttributedString *attributedLanguage = styleText(language, 10, SAVED_PAGES_LANGUAGE_COLOR);
    
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
    cell.imageView.image = [UIImage imageNamed:@"logo-search-placeholder.png"];
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

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [NAV loadArticleWithTitle: savedEntry.article.title
                       domain: savedEntry.article.domain
                     animated: YES
              discoveryMethod: DISCOVERY_METHOD_SEARCH];
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
            [articleDataContext_.mainContext deleteObject:savedEntry];
            [articleDataContext_.mainContext save:&error];
            
            [self.savedPagesDataArray[indexPath.section][@"data"] removeObject:savedEntryId];
            
            [self.tableView endUpdates];
        }
    }];
}

@end
