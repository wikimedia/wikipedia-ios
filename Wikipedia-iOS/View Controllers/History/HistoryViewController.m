//  Created by Monte Hurd on 12/4/13.

#import "HistoryViewController.h"
#import "NSDate-Utilities.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "HistoryResultCell.h"
#import "HistoryTableHeadingLabel.h"
#import "Defines.h"
#import "Article+Convenience.h"
#import "UINavigationController+SearchNavStack.h"
#import "NavController.h"

#define NAV ((NavController *)self.navigationController)

#define HISTORY_THUMBNAIL_WIDTH 110
#define HISTORY_RESULT_HEIGHT 66
#define HISTORY_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define HISTORY_LANGUAGE_COLOR [UIColor colorWithWhite:0.0f alpha:0.4f]
#define HISTORY_DATE_HEADER_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.6f]
#define HISTORY_DATE_HEADER_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.97f]
#define HISTORY_DATE_HEADER_HEIGHT 51.0f
#define HISTORY_DATE_HEADER_LEFT_PADDING 37.0f

@interface HistoryViewController ()
{
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, atomic) NSMutableArray *historyDataArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation HistoryViewController

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

    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setLocale:[NSLocale currentLocale]];
    [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.historyDataArray = [[NSMutableArray alloc] init];
    
    [self getHistoryData];

    HistoryTableHeadingLabel *historyLabel = [[HistoryTableHeadingLabel alloc] initWithFrame:CGRectMake(0, 0, 10, 48)];
    historyLabel.text = NSLocalizedString(@"history-label", nil);
    historyLabel.textAlignment = NSTextAlignmentCenter;
    historyLabel.font = [UIFont boldSystemFontOfSize:20.0];
    historyLabel.textColor = HISTORY_TEXT_COLOR;
    self.tableView.tableHeaderView = historyLabel;
    historyLabel.backgroundColor = [UIColor whiteColor];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    // Register the history results cell for reuse
    [self.tableView registerNib:[UINib nibWithNibName:@"HistoryResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"HistoryResultCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - History data

-(void)getHistoryData
{
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"History"
                                              inManagedObjectContext: articleDataContext_.mainContext];
    [fetchRequest setEntity:entity];
    
    // For now fetch all history records - history entries older than 30 days will
    // be placed into "garbage" array below and removed.
    //[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"dateVisited > %@", [[NSDate date] dateBySubtractingDays:30]]];

    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:NO selector:nil];

    [fetchRequest setSortDescriptors:@[dateSort]];

    NSMutableArray *today = [@[] mutableCopy];
    NSMutableArray *yesterday = [@[] mutableCopy];
    NSMutableArray *lastWeek = [@[] mutableCopy];
    NSMutableArray *lastMonth = [@[] mutableCopy];
    NSMutableArray *garbage = [@[] mutableCopy];

    error = nil;
    NSArray *historyEntities = [articleDataContext_.mainContext executeFetchRequest:fetchRequest error:&error];
    //XCTAssert(error == nil, @"Could not fetch.");
    for (History *history in historyEntities) {
        /*
        NSLog(@"HISTORY:\n\t\
            article: %@\n\t\
            site: %@\n\t\
            domain: %@\n\t\
            date: %@\n\t\
            method: %@\n\t\
            image: %@",
            history.article.title,
            history.article.site,
            history.article.domain,
            history.dateVisited,
            history.discoveryMethod,
            history.article.thumbnailImage.fileName
        );
        */

        if ([history.dateVisited isToday]) {
            [today addObject:history.objectID];
        }else if ([history.dateVisited isYesterday]) {
            [yesterday addObject:history.objectID];
        }else if ([history.dateVisited isLaterThanDate:[[NSDate date] dateBySubtractingDays:7]]) {
            [lastWeek addObject:history.objectID];
        }else if ([history.dateVisited isLaterThanDate:[[NSDate date] dateBySubtractingDays:30]]) {
            [lastMonth addObject:history.objectID];
        }else{
            // Older than 30 days == Garbage! Remove!
            [garbage addObject:history.objectID];
        }
    }
    
    [self removeGarbage:garbage];

    if (today.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": today,
                                            @"sectionTitle": NSLocalizedString(@"history-section-today", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForToday]
                                            }
                                          mutableCopy]];
    if (yesterday.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": yesterday,
                                            @"sectionTitle": NSLocalizedString(@"history-section-yesterday", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForYesterday]
                                            }
                                          mutableCopy]];
    if (lastWeek.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": lastWeek,
                                            @"sectionTitle": NSLocalizedString(@"history-section-lastweek", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForLastWeek]
                                            }
                                          mutableCopy]];
    if (lastMonth.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": lastMonth,
                                            @"sectionTitle": NSLocalizedString(@"history-section-lastmonth", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForLastMonth]
                                            }
                                          mutableCopy]];
}

#pragma mark - History garbage removal

-(void) removeGarbage:(NSMutableArray *)garbage
{
    //NSLog(@"GARBAGE COUNT = %lu", (unsigned long)garbage.count);
    //NSLog(@"GARBAGE = %@", garbage);
    if (garbage.count == 0) return;

    [articleDataContext_.mainContext performBlockAndWait:^(){
        for (NSManagedObjectID *historyID in garbage) {
            History *history = (History *)[articleDataContext_.mainContext objectWithID:historyID];
            Article *article = history.article;
            Image *thumb = history.article.thumbnailImage;
            
            // Delete the expired history record
            [articleDataContext_.mainContext deleteObject:history];

            BOOL isSaved = (article.saved.count > 0) ? YES : NO;

            if (isSaved) continue;

            // Article deletes don't cascade to images (intentionally) so delete these manually.
            if (thumb) [articleDataContext_.mainContext deleteObject:thumb];

//TODO: add code for deleting images which were only referenced by this article

            // Delete the article
            if (article) [articleDataContext_.mainContext deleteObject:article];

        }
        NSError *error = nil;
        [articleDataContext_.mainContext save:&error];
        if (error) NSLog(@"GARBAGE error = %@", error);

    }];
}

#pragma mark - History section titles

-(NSString *)getHistorySectionTitleForToday
{
    [self.dateFormatter setDateFormat:@"MMMM dd yyyy"];
    return [self.dateFormatter stringFromDate:[NSDate date]];
}

-(NSString *)getHistorySectionTitleForYesterday
{
    [self.dateFormatter setDateFormat:@"MMMM dd yyyy"];
    return [self.dateFormatter stringFromDate:[NSDate dateYesterday]];
}

-(NSString *)getHistorySectionTitleForLastWeek
{
    // Couldn't use just a single month name because 7 days ago could spans 2 months.
    [self.dateFormatter setDateFormat:@"%@ - %@"];
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    [self.dateFormatter setDateFormat:@"MMM dd yyyy"];
    NSString *d1 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:7]];
    NSString *d2 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:2]];
    return [NSString stringWithFormat:dateString, d1, d2];
}

-(NSString *)getHistorySectionTitleForLastMonth
{
    // Couldn't use just a single month name because 30 days ago probably spans 2 months.
    /*
     [self.dateFormatter setDateFormat:@"MMMM yyyy"];
     return [self.dateFormatter stringFromDate:[NSDate date]];
     */
    [self.dateFormatter setDateFormat:@"%@ - %@"];
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    [self.dateFormatter setDateFormat:@"MMM dd yyyy"];
    NSString *d1 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:30]];
    NSString *d2 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:8]];
    return [NSString stringWithFormat:dateString, d1, d2];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.historyDataArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Number of rows it should expect should be based on the section
    NSDictionary *dict = self.historyDataArray[section];
    NSArray *array = [dict objectForKey:@"data"];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"HistoryResultCell";
    HistoryResultCell *cell = (HistoryResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSDictionary *dict = self.historyDataArray[indexPath.section];
    NSArray *array = [dict objectForKey:@"data"];
    
    __block History *historyEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *historyEntryId = (NSManagedObjectID *)array[indexPath.row];
        historyEntry = (History *)[articleDataContext_.mainContext objectWithID:historyEntryId];
    }];
    
    NSString *title = [historyEntry.article.title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    NSString *language = [NSString stringWithFormat:@"\n%@", historyEntry.article.domainName];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;

    NSMutableAttributedString *(^styleText)(NSString *, CGFloat, UIColor *) = ^NSMutableAttributedString *(NSString *str, CGFloat size, UIColor *color){
        return [[NSMutableAttributedString alloc] initWithString:str attributes: @{
            NSFontAttributeName : [UIFont boldSystemFontOfSize:size],
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : color,
        }];
    };

    NSMutableAttributedString *attributedTitle = styleText(title, 15, HISTORY_TEXT_COLOR);
    NSMutableAttributedString *attributedLanguage = styleText(language, 8, HISTORY_LANGUAGE_COLOR);
    
    [attributedTitle appendAttributedString:attributedLanguage];
    cell.textLabel.attributedText = attributedTitle;

//TODO: pull this out so not loading image from file more than once.
    NSString *imageName = [NSString stringWithFormat:@"history-%@.png", historyEntry.discoveryMethod];
    cell.methodImageView.image = [UIImage imageNamed:imageName];

    UIImage *thumbImage = [historyEntry.article getThumbnailUsingContext:articleDataContext_.mainContext];
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
    NSDictionary *dict = self.historyDataArray[indexPath.section];
    NSArray *array = dict[@"data"];
    selectedCell = array[indexPath.row];
    
    __block History *historyEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *historyEntryId = (NSManagedObjectID *)array[indexPath.row];
        historyEntry = (History *)[articleDataContext_.mainContext objectWithID:historyEntryId];
    }];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [NAV loadArticleWithTitle:historyEntry.article.title domain:historyEntry.article.domain animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return HISTORY_RESULT_HEIGHT;
}

#pragma mark - Table headers

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = self.historyDataArray[section];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = HISTORY_DATE_HEADER_BACKGROUND_COLOR;
    view.autoresizesSubviews = YES;
    UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.backgroundColor = [UIColor clearColor];

    NSString *title = dict[@"sectionTitle"];
    NSString *dateString = dict[@"sectionDateString"];

    label.attributedText = [self getAttributedHeaderForTitle:title dateString:dateString];

    [view addSubview:label];

    return view;
}

-(NSAttributedString *)getAttributedHeaderForTitle:(NSString *)title dateString:(NSString *)dateString
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    paragraphStyle.firstLineHeadIndent = HISTORY_DATE_HEADER_LEFT_PADDING;
    
    NSString *header = [NSString stringWithFormat:@"%@ %@", title, dateString];
    NSMutableAttributedString *attributedHeader = [[NSMutableAttributedString alloc] initWithString: header];
    
    NSRange rangeOfHeader = NSMakeRange(0, header.length);
    NSRange rangeOfTitle = NSMakeRange(0, title.length);
    NSRange rangeOfDateString = NSMakeRange(title.length + 1, dateString.length);
    
    [attributedHeader addAttributes:@{
                                      NSParagraphStyleAttributeName: paragraphStyle
                                      } range:rangeOfHeader];
    
    [attributedHeader addAttributes:@{
                                      NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0],
                                      NSForegroundColorAttributeName : HISTORY_DATE_HEADER_TEXT_COLOR
                                      } range:rangeOfTitle];
    
    [attributedHeader addAttributes:@{
                                      NSFontAttributeName : [UIFont systemFontOfSize:12.0],
                                      NSForegroundColorAttributeName : HISTORY_DATE_HEADER_TEXT_COLOR
                                      } range:rangeOfDateString];
    return attributedHeader;
}

#pragma mark - Delete

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.tableView.editing = NO;
        [self performSelector:@selector(deleteHistoryForIndexPath:) withObject:indexPath afterDelay:0.15f];
    }
}

-(void)deleteHistoryForIndexPath:(NSIndexPath *)indexPath
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *historyEntryId = (NSManagedObjectID *)self.historyDataArray[indexPath.section][@"data"][indexPath.row];
        History *historyEntry = (History *)[articleDataContext_.mainContext objectWithID:historyEntryId];
        if (historyEntry) {
            
            [self.tableView beginUpdates];

            NSUInteger itemsInSection = [(NSArray *)self.historyDataArray[indexPath.section][@"data"] count];
            
            if (itemsInSection == 1) {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            }
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            NSError *error = nil;
            [articleDataContext_.mainContext deleteObject:historyEntry];
            [articleDataContext_.mainContext save:&error];
            
            if (itemsInSection == 1) {
                [self.historyDataArray removeObjectAtIndex:indexPath.section];
            }else{
                [self.historyDataArray[indexPath.section][@"data"] removeObject:historyEntryId];
            }
            
            [self.tableView endUpdates];
        }
    }];
}

@end
