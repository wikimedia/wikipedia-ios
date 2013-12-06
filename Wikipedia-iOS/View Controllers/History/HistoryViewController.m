//  Created by Monte Hurd on 12/4/13.

#import "HistoryViewController.h"
#import "NSDate-Utilities.h"
#import <CoreData/CoreData.h>
#import "Article.h"
#import "DiscoveryContext.h"
#import "DataContextSingleton.h"
#import "Section.h"
#import "History.h"
#import "Saved.h"
#import "DiscoveryMethod.h"
#import "Image.h"
#import "Site.h"
#import "Domain.h"
#import "WebViewController.h"
#import "HistoryResultCell.h"
#import "HistoryTableHeadingLabel.h"

#define HISTORY_THUMBNAIL_WIDTH 110
#define HISTORY_RESULT_HEIGHT 66

#define HISTORY_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define HISTORY_DATE_HEADER_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.6f]
#define HISTORY_DATE_HEADER_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.97f]
#define HISTORY_DATE_HEADER_HEIGHT 51.0f
#define HISTORY_DATE_HEADER_LEFT_PADDING 37.0f

//TODO: fix bug with separate history entries being entered if same search term, but with differing capitalization is used. ie: search for "History of China" then select the "History of China" result. Then search for "history of china" and select the "History of China" result again. There will be 2 history entries.

@interface HistoryViewController ()
{
    NSMutableArray *dataArray;
}

@end

@implementation HistoryViewController

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
    
    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    dataArray = [[NSMutableArray alloc] init];
    
    [self getHistoryData];
    [self getHistorySectionTitleDateStrings];

    HistoryTableHeadingLabel *historyLabel = [[HistoryTableHeadingLabel alloc] initWithFrame:CGRectMake(0, 0, 10, 48)];
    historyLabel.text = @"Browsing History";
    historyLabel.textAlignment = NSTextAlignmentCenter;
    historyLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
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
    DataContextSingleton *dataContext = [DataContextSingleton sharedInstance];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"History"
                                              inManagedObjectContext: dataContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"dateVisited > %@", [[NSDate date] dateBySubtractingDays:30]]];

    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:NO selector:nil];

    [fetchRequest setSortDescriptors:@[dateSort]];

    NSMutableArray *today = [@[] mutableCopy];
    NSMutableArray *yesterday = [@[] mutableCopy];
    NSMutableArray *lastWeek = [@[] mutableCopy];
    NSMutableArray *lastMonth = [@[] mutableCopy];

    error = nil;
    NSArray *historyEntities = [dataContext executeFetchRequest:fetchRequest error:&error];
    //XCTAssert(error == nil, @"Could not fetch.");
    for (History *history in historyEntities) {
        NSLog(@"HISTORY:\n\t\
            article: %@\n\t\
            site: %@\n\t\
            domain: %@\n\t\
            date: %@\n\t\
            method: %@\n\t\
            image: %@",
            history.article.title,
            history.article.site.name,
            history.article.domain.name,
            history.dateVisited,
            history.discoveryMethod.name,
            history.article.thumbnailImage.fileName
        );
        
        if ([history.dateVisited isToday]) {
            [today addObject:history];
        }else if ([history.dateVisited isYesterday]) {
            [yesterday addObject:history];
        }else if ([history.dateVisited isLaterThanDate:[[NSDate date] dateBySubtractingDays:7]]) {
            [lastWeek addObject:history];
        }else if ([history.dateVisited isLaterThanDate:[[NSDate date] dateBySubtractingDays:30]]) {
            [lastMonth addObject:history];
        }
    }
    
    [dataArray addObject:[@{@"data": today, @"sectionTitle": @"Today", @"sectionDateString": @""} mutableCopy]];
    [dataArray addObject:[@{@"data": yesterday, @"sectionTitle": @"Yesterday", @"sectionDateString": @""} mutableCopy]];
    [dataArray addObject:[@{@"data": lastWeek, @"sectionTitle": @"Last week", @"sectionDateString": @""} mutableCopy]];
    [dataArray addObject:[@{@"data": lastMonth, @"sectionTitle": @"Last month", @"sectionDateString": @""} mutableCopy]];
}

#pragma mark - History section titles

-(void)getHistorySectionTitleDateStrings
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setLocale:[NSLocale currentLocale]];
    [dateFormat setTimeZone:[NSTimeZone localTimeZone]];
    NSString *dateString = @"";

    // Today date string
    [dateFormat setDateFormat:@"MMMM dd yyyy"];
    dateString = [dateFormat stringFromDate:[NSDate date]];
    dataArray[0][@"sectionDateString"] = dateString;

    // Yesterday date string
    [dateFormat setDateFormat:@"MMMM dd yyyy"];
    dateString = [dateFormat stringFromDate:[NSDate dateYesterday]];
    dataArray[1][@"sectionDateString"] = dateString;

    // Last week date string
    // Couldn't use just a single month name because 7 days ago could spans 2 months.
    [dateFormat setDateFormat:@"%@ - %@"];
    dateString = [dateFormat stringFromDate:[NSDate date]];
    [dateFormat setDateFormat:@"MMM dd yyyy"];
    NSString *d1 = [dateFormat stringFromDate:[NSDate dateWithDaysBeforeNow:7]];
    NSString *d2 = [dateFormat stringFromDate:[NSDate dateWithDaysBeforeNow:2]];
    NSString *lastWeekDateString = [NSString stringWithFormat:dateString, d1, d2];
    dataArray[2][@"sectionDateString"] = lastWeekDateString;

    // Last month date string
    // Couldn't use just a single month name because 30 days ago probably spans 2 months.
    /*
    [dateFormat setDateFormat:@"MMMM yyyy"];
    dateString = [dateFormat stringFromDate:[NSDate date]];
    dataArray[3][@"sectionDateString"] = dateString;
    */
    [dateFormat setDateFormat:@"%@ - %@"];
    dateString = [dateFormat stringFromDate:[NSDate date]];
    [dateFormat setDateFormat:@"MMM dd yyyy"];
    d1 = [dateFormat stringFromDate:[NSDate dateWithDaysBeforeNow:30]];
    d2 = [dateFormat stringFromDate:[NSDate dateWithDaysBeforeNow:8]];
    NSString *lastMonthDateString = [NSString stringWithFormat:dateString, d1, d2];
    dataArray[3][@"sectionDateString"] = lastMonthDateString;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [dataArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Number of rows it should expect should be based on the section
    NSDictionary *dict = dataArray[section];
    NSArray *array = [dict objectForKey:@"data"];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"HistoryResultCell";
    HistoryResultCell *cell = (HistoryResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSDictionary *dict = dataArray[indexPath.section];
    NSArray *array = [dict objectForKey:@"data"];
    
    History *historyEntry = (History *)array[indexPath.row];
    
    NSString *title = [historyEntry.article.title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    
    cell.textLabel.text = title;
    cell.textLabel.textColor = HISTORY_TEXT_COLOR;
    
//TODO: pull this out so not loading image from file more than once.
    NSString *imageName = [NSString stringWithFormat:@"history-%@.png", historyEntry.discoveryMethod.name];
    cell.methodImageView.image = [UIImage imageNamed:imageName];

    Image *thumbnailFromDB = historyEntry.article.thumbnailImage;
    if(thumbnailFromDB){
        UIImage *image = [UIImage imageWithData:thumbnailFromDB.data];
        cell.imageView.image = image;
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
    NSDictionary *dict = dataArray[indexPath.section];
    NSArray *array = dict[@"data"];
    selectedCell = array[indexPath.row];
    
    History *historyEntry = (History *)array[indexPath.row];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WebViewController *webViewController = [self getWebViewController];
    [webViewController navigateToPage:historyEntry.article.title discoveryMethod:historyEntry.discoveryMethod];
    [self.navigationController popToViewController:webViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return HISTORY_RESULT_HEIGHT;
}

#pragma mark - Table headers

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    NSDictionary *dict = dataArray[section];
    NSMutableArray *a = (NSMutableArray *) dict[@"data"];
    if(a.count == 0) return 0;

    return HISTORY_DATE_HEADER_HEIGHT;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = dataArray[section];
    
    // Don't show header if no items in this section!
    NSMutableArray *a = (NSMutableArray *) dict[@"data"];
    if(a.count == 0) return nil;


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
                                      NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:12],
                                      NSForegroundColorAttributeName : HISTORY_DATE_HEADER_TEXT_COLOR
                                      } range:rangeOfTitle];
    
    [attributedHeader addAttributes:@{
                                      NSFontAttributeName : [UIFont fontWithName:@"Helvetica" size:12],
                                      NSForegroundColorAttributeName : HISTORY_DATE_HEADER_TEXT_COLOR
                                      } range:rangeOfDateString];
    return attributedHeader;
}

#pragma mark - Misc

-(WebViewController *)getWebViewController
{
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[WebViewController class]]) {
            return (WebViewController *)vc;
        }
    }
    return nil;
}

@end
