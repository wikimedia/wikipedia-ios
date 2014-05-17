//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BottomMenuViewController.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "SessionSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "LanguagesTableVC.h"

@interface BottomMenuViewController ()

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *langButton;

@property (strong, nonatomic) NSDictionary *adjacentHistoryIDs;

@end

@implementation BottomMenuViewController{

    ArticleDataContextSingleton *articleDataContext_;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
}

#pragma mark Bottom bar button methods

//TODO: Pull bottomBarView and into own object (and its subviews - the back and forward view/buttons/methods, etc).

- (IBAction)backButtonPushed:(id)sender
{
    NSManagedObjectID *historyId = self.adjacentHistoryIDs[@"before"];
    if (historyId){
        History *history = (History *)[articleDataContext_.mainContext objectWithID:historyId];

        WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];

        [webVC navigateToPage: history.article.title
                      domain: history.article.domain
             discoveryMethod: DISCOVERY_METHOD_SEARCH
           invalidatingCache: NO];
    }
}

- (IBAction)forwardButtonPushed:(id)sender
{
    NSManagedObjectID *historyId = self.adjacentHistoryIDs[@"after"];
    if (historyId){
        History *history = (History *)[articleDataContext_.mainContext objectWithID:historyId];

        WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];

        [webVC navigateToPage: history.article.title
                      domain: history.article.domain
             discoveryMethod: DISCOVERY_METHOD_SEARCH
           invalidatingCache: NO];
    }
}

-(NSDictionary *)getAdjacentHistoryIDs
{
    __block NSManagedObjectID *currentHistoryId = nil;
    __block NSManagedObjectID *beforeHistoryId = nil;
    __block NSManagedObjectID *afterHistoryId = nil;
    
    [articleDataContext_.workerContext performBlockAndWait:^(){
        
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName: @"History"
                                                  inManagedObjectContext: articleDataContext_.workerContext];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:YES selector:nil];
        
        [fetchRequest setSortDescriptors:@[dateSort]];
        
        error = nil;
        NSArray *historyEntities = [articleDataContext_.workerContext executeFetchRequest:fetchRequest error:&error];
        
        NSManagedObjectID *currentArticleId = [articleDataContext_.workerContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                               domain: [SessionSingleton sharedInstance].currentArticleDomain];
        for (NSUInteger i = 0; i < historyEntities.count; i++) {
            History *history = historyEntities[i];
            if (history.article.objectID == currentArticleId){
                currentHistoryId = history.objectID;
                if (i > 0) {
                    History *beforeHistory = historyEntities[i - 1];
                    beforeHistoryId = beforeHistory.objectID;
                }
                if ((i + 1) <= (historyEntities.count - 1)) {
                    History *afterHistory = historyEntities[i + 1];
                    afterHistoryId = afterHistory.objectID;
                }
                break;
            }
        }
    }];

    NSMutableDictionary *result = [@{} mutableCopy];
    if(beforeHistoryId) result[@"before"] = beforeHistoryId;
    if(currentHistoryId) result[@"current"] = currentHistoryId;
    if(afterHistoryId) result[@"after"] = afterHistoryId;

    return result;
}

-(void)updateBottomBarButtonsEnabledStateWithLangCount:(NSNumber *)langCount
{
    self.adjacentHistoryIDs = [self getAdjacentHistoryIDs];
    self.forwardButton.enabled = (self.adjacentHistoryIDs[@"after"]) ? YES : NO;
    self.backButton.enabled = (self.adjacentHistoryIDs[@"before"]) ? YES : NO;
    
    if ([[SessionSingleton sharedInstance] isCurrentArticleMain]) {
        // Disable the article languages buttons if this is the main page.
        self.langButton.enabled = NO;
    }else{
        self.langButton.enabled = (langCount.integerValue > 1) ? YES : NO;
    }
}

- (IBAction)languageButtonPushed:(id)sender
{
    [self showLanguages];
}

-(void)showLanguages
{
    LanguagesTableVC *languagesTableVC =
        [NAV.storyboard instantiateViewControllerWithIdentifier:@"LanguagesTableVC"];

    languagesTableVC.downloadLanguagesForCurrentArticle = YES;
    
    CATransition *transition = [languagesTableVC getTransition];
    
    languagesTableVC.selectionBlock = ^(NSDictionary *selectedLangInfo){
    
        [NAV.view.layer addAnimation:transition forKey:nil];
        // Don't animate - so the transistion set above will be used.
        [NAV loadArticleWithTitle: selectedLangInfo[@"*"]
                           domain: selectedLangInfo[@"code"]
                         animated: NO
                  discoveryMethod: DISCOVERY_METHOD_SEARCH
                invalidatingCache: NO];
    };
    
    [NAV.view.layer addAnimation:transition forKey:nil];

    // Don't animate - so the transistion set above will be used.
    [NAV pushViewController:languagesTableVC animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
