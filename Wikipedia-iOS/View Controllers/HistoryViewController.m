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

#define HISTORY_THUMBNAIL_WIDTH 110
#define HISTORY_RESULT_HEIGHT 60

@interface HistoryViewController ()
{
    NSMutableArray *dataArray;
}

@end

@implementation HistoryViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

    UILabel *historyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 48)];
    historyLabel.text = @"Browsing History";
    historyLabel.textAlignment = NSTextAlignmentCenter;
    historyLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
    historyLabel.textColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
    self.tableView.tableHeaderView = historyLabel;
    historyLabel.backgroundColor = [UIColor whiteColor];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
}

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
        }else if ([history.dateVisited isLastWeek]) {
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
    [dateFormat setDateFormat:@"%@ - %@"];
    dateString = [dateFormat stringFromDate:[NSDate date]];
    [dateFormat setDateFormat:@"MMM dd yyyy"];
    NSString *d1 = [dateFormat stringFromDate:[NSDate dateWithDaysBeforeNow:7]];
    NSString *d2 = [dateFormat stringFromDate:[NSDate dateWithDaysBeforeNow:2]];
    NSString *lastWeekDateString = [NSString stringWithFormat:dateString, d1, d2];
    dataArray[2][@"sectionDateString"] = lastWeekDateString;

    // Last month date string
    [dateFormat setDateFormat:@"MMMM yyyy"];
    dateString = [dateFormat stringFromDate:[NSDate date]];
    dataArray[3][@"sectionDateString"] = dateString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *dict = dataArray[section];
    
    // Don't show header if no items in this section!
    NSMutableArray *a = (NSMutableArray *) dict[@"data"];
    if(a.count == 0) return nil;
    
    return [NSString stringWithFormat:@"%@ %@", dict[@"sectionTitle"], dict[@"sectionDateString"]];
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSDictionary *dict = dataArray[section];
    return [NSString stringWithFormat:@"Footer for section %@", dict[@"sectionTitle"]];
}
*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    NSDictionary *dict = dataArray[indexPath.section];
    NSArray *array = [dict objectForKey:@"data"];
    
    History *historyEntry = (History *)array[indexPath.row];
    
    NSString *title = [historyEntry.article.title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    
    cell.textLabel.text = title;
    
    cell.imageView.image = [UIImage imageWithData:historyEntry.article.thumbnailImage.data];
    
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

-(WebViewController *)getWebViewController
{
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[WebViewController class]]) {
            return (WebViewController *)vc;
        }
    }
    return nil;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
