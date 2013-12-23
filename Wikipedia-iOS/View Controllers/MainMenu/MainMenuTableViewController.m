//  Created by Monte Hurd on 12/18/13.

#import "MainMenuTableViewController.h"
#import "MainMenuSectionHeadingLabel.h"

#import "ArticleDataContextSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "ArticleCoreDataObjects.h"
#import "Article+Convenience.h"

@interface MainMenuTableViewController (){
}

@property (strong, atomic) NSMutableDictionary *menuDataDict;

@end

@implementation MainMenuTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.hidesBackButton = YES;
    self.menuDataDict = [[NSMutableDictionary alloc] init];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
   
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    // Register the menu results cell for reuse
    [self.tableView registerNib:[UINib nibWithNibName:@"MainMenuResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"MainMenuResultsCell"];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.menuDataDict removeAllObjects];
    
    [self loadMenuDataDict];
    
    [self.tableView reloadData];
}

-(void)loadMenuDataDict
{
    NSString *lastViewedArticleTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastViewedArticleTitle"];

    if(!lastViewedArticleTitle) return;
    if(lastViewedArticleTitle.length == 0) return;

    self.menuDataDict = [@{
                           
           @"menuOptions": [@{
                              @"sectionTitle": @"Show me...",
                              @"sectionLabel": @"",
                              @"sectionSubTitle": @"",
                              @"sectionOptions": @{
                                      
                                      @"savedPages": [@{
                                                        @"title": @"  💾  My Saved Pages",
                                                        @"label": @""
                                                        } mutableCopy]
                                      
                                      ,
                                      
                                      @"history": [@{
                                                     @"title": @"  📖  My Browsing History",
                                                     @"label": @""
                                                     } mutableCopy]
                                      
                                      }
                              } mutableCopy]
           
           ,
           
           @"articleOptions": [@{
                                 @"sectionTitle": [NSString stringWithFormat:@"\"%@\"", lastViewedArticleTitle],
                                 @"sectionLabel": @"",
                                 @"sectionSubTitle": @"",
                                 @"sectionOptions": @{
                                         @"savePage": [@{
                                                         @"title": @"  💾  Save for Offline Reading",
                                                         @"label": @""
                                                         } mutableCopy]
                                         
                                         ,
                                         @"debugPage": [@{
                                                         @"title": @"  👀 Section Images to Console",
                                                         @"label": @""
                                                         } mutableCopy]
                                         
                                         }
                                 } mutableCopy]
           
           } mutableCopy];
    return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.menuDataDict count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionOptions = self.menuDataDict[self.menuDataDict.allKeys[section]][@"sectionOptions"];
    return sectionOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainMenuResultsCell" forIndexPath:indexPath];
    
    NSDictionary *sectionOptions = self.menuDataDict[self.menuDataDict.allKeys[indexPath.section]][@"sectionOptions"];

    sectionOptions[sectionOptions.allKeys[indexPath.row]][@"label"] = cell.textLabel;

    NSString *title = sectionOptions[sectionOptions.allKeys[indexPath.row]][@"title"];
    cell.textLabel.numberOfLines = 2;

    cell.textLabel.text = title;
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSMutableDictionary *sectionDict = self.menuDataDict[self.menuDataDict.allKeys[section]];
    
    // Don't show header if no items in this section.
    NSDictionary *sectionOptions = sectionDict[@"sectionOptions"];
    if (sectionOptions.count == 0) {
        return nil;
    }
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithWhite:0.97f alpha:0.97f];
    
    MainMenuSectionHeadingLabel *label = [[MainMenuSectionHeadingLabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    label.useDottedLine = NO; // (section == 0) ? NO : YES ;
    
    NSString *title = sectionDict[@"sectionTitle"];
    //NSString *subTitle = dict[@"sectionSubTitle"];
    
    //label.text = [NSString stringWithFormat:@"  %@ - %@", title, subTitle];
    label.text = [NSString stringWithFormat:@"%@", title];
    
    sectionDict[@"sectionLabel"] = label;
    
    [view addSubview:label];
    [view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[label]-10-|" options:0 metrics:nil views:@{@"label":label}]];
    [view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[label]-0-|" options:0 metrics:nil views:@{@"label":label}]];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 53;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    return 63;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionDict = self.menuDataDict[self.menuDataDict.allKeys[indexPath.section]];
    NSDictionary *sectionOptions = sectionDict[@"sectionOptions"];
    NSString *selectedKey = sectionOptions.allKeys[indexPath.row];
    //NSLog(@"menu item selection key = %@", selectedKey);
    
    if ([selectedKey isEqualToString:@"history"]) {
        [self.navigationController popViewControllerAnimated:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HistoryToggle" object:self userInfo:nil];
    }else if ([selectedKey isEqualToString:@"savedPages"]) {
        [self.navigationController popViewControllerAnimated:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SavedPagesToggle" object:self userInfo:nil];
    }else if ([selectedKey isEqualToString:@"savePage"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SavePage" object:self userInfo:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        [self animateArticleTitleMovingToSavedPages];
    }else if ([selectedKey isEqualToString:@"debugPage"]) {

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSLog(@"DEBUG PAGE!");

        NSString *lastViewedArticleTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastViewedArticleTitle"];
        if(lastViewedArticleTitle) {
            ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
            [articleDataContext_.workerContext performBlock:^{
                NSManagedObjectID *articleID = [articleDataContext_.workerContext getArticleIDForTitle:lastViewedArticleTitle];
                Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
                if (article) {
                    NSArray *sectionImages = [article getSectionImagesUsingContext:articleDataContext_.workerContext];
                    for (SectionImage *sectionImage in sectionImages) {
                        NSLog(@"\nsectionImage: \n\tsection index %@\n\timage index %@\n\tfile name %@\n\talt %@",
                              sectionImage.section.index,
                              sectionImage.index,
                              sectionImage.image.fileName,
                              sectionImage.image.alt
                              );
                    }
                }
            }];
        }
    }
}

#pragma mark - Sage page animation

-(void)animateArticleTitleMovingToSavedPages
{
    UILabel *savedPagesLabel = self.menuDataDict[@"menuOptions"][@"sectionOptions"][@"savedPages"][@"label"];
    UILabel *articleTitleLabel = self.menuDataDict[@"articleOptions"][@"sectionLabel"];
    CGAffineTransform scale = CGAffineTransformMakeScale(0.4, 0.4);
    CGPoint destPoint = [self getLocationForView:savedPagesLabel xf:scale];
    
    [self animateView:[self getLabelCopyToAnimate:articleTitleLabel] toDestination:destPoint afterDelay:0.0 duration:0.45f transform:scale];
    [self animateView:[self getLabelCopyToAnimate:articleTitleLabel] toDestination:destPoint afterDelay:0.06 duration:0.45f transform:scale];
    [self animateView:[self getLabelCopyToAnimate:articleTitleLabel] toDestination:destPoint afterDelay:0.12 duration:0.45f transform:scale];
    [self animateView:[self getLabelCopyToAnimate:articleTitleLabel] toDestination:destPoint afterDelay:0.18 duration:0.45f transform:scale];

    [self animateAndRewindXF:CATransform3DMakeScale(1.08f, 1.08f, 1.0f) forView:savedPagesLabel afterDelay:0.33 duration:0.17];
}

-(void)animateAndRewindXF:(CATransform3D)xf forView:(UIView *)view afterDelay:(CGFloat)delay duration:(CGFloat)duration
{
    CABasicAnimation *(^animatePathToValue)(NSString *, NSValue *, CGFloat, CGFloat) = ^(NSString *path, NSValue *toValue, CGFloat duration, CGFloat delay){
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:path];
        a.fillMode = kCAFillModeForwards;
        a.autoreverses = YES;
        a.duration = duration;
        a.removedOnCompletion = YES;
        [a setBeginTime:CACurrentMediaTime() + delay];
        a.toValue = toValue;
        return a;
    };
    [view.layer addAnimation:animatePathToValue(@"transform", [NSValue valueWithCATransform3D:xf], duration, delay) forKey:nil];
}

-(UILabel *)getLabelCopyToAnimate:(UILabel *)labelToCopy
{
    UILabel *labelCopy = [[UILabel alloc] init];
    CGRect sourceRect = [labelToCopy convertRect:labelToCopy.bounds toView:self.tableView];
    labelCopy.frame = sourceRect;
    labelCopy.text = labelToCopy.text;
    labelCopy.font = labelToCopy.font;
    labelCopy.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    labelCopy.textAlignment = labelToCopy.textAlignment;
    labelCopy.lineBreakMode = labelToCopy.lineBreakMode;
    labelCopy.numberOfLines = labelToCopy.numberOfLines;
    [self.tableView addSubview:labelCopy];
    return labelCopy;
}

-(CGPoint)getLocationForView:(UIView *)view xf:(CGAffineTransform)xf
{
    CGPoint point = [view convertPoint:view.center toView:self.tableView];
    CGPoint scaledPoint = [view convertPoint:CGPointApplyAffineTransform(view.center, xf) toView:self.tableView];
    scaledPoint.y = point.y;
    return scaledPoint;
}

-(void)animateView:(UIView *)view toDestination:(CGPoint)destPoint afterDelay:(CGFloat)delay duration:(CGFloat)duration transform:(CGAffineTransform)xf
{
    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.center = destPoint;
        view.alpha = 0.3f;
        view.transform = xf;
    }completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}

@end
