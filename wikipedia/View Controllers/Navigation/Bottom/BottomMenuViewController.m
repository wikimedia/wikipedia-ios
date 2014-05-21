//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BottomMenuViewController.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "SessionSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "WMF_WikiFont_Chars.h"
#import "TopMenuButtonView.h"
#import "TopMenuLabel.h"
#import "UIViewController+Alert.h"

typedef NS_ENUM(NSInteger, BottomMenuItemTag) {
    BOTTOM_MENU_BUTTON_UNKNOWN = 0,
    BOTTOM_MENU_BUTTON_PREVIOUS = 1,
    BOTTOM_MENU_BUTTON_NEXT = 2,
    BOTTOM_MENU_BUTTON_SHARE = 3
};

@interface BottomMenuViewController ()

@property (weak, nonatomic) IBOutlet TopMenuButtonView *backButton;
@property (weak, nonatomic) IBOutlet TopMenuButtonView *forwardButton;
@property (weak, nonatomic) IBOutlet TopMenuButtonView *rightButton;

@property (strong, nonatomic) NSDictionary *adjacentHistoryIDs;

@property (strong, nonatomic) NSArray *allButtons;

@end

@implementation BottomMenuViewController{

    ArticleDataContextSingleton *articleDataContext_;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    [self.backButton.label setWikiText:WIKIFONT_CHAR_IOS_BACKWARD];
    self.backButton.tag = BOTTOM_MENU_BUTTON_PREVIOUS;

    [self.forwardButton.label setWikiText:WIKIFONT_CHAR_IOS_FORWARD];
    self.forwardButton.tag = BOTTOM_MENU_BUTTON_NEXT;

    [self.rightButton.label setWikiText:WIKIFONT_CHAR_IOS_SHARE];
    self.rightButton.tag = BOTTOM_MENU_BUTTON_SHARE;

    self.allButtons = @[self.backButton, self.forwardButton, self.rightButton];

    [self addTapRecognizersToAllButtons];
}

-(void)addTapRecognizersToAllButtons
{
    for (TopMenuButtonView *view in self.allButtons) {
        [view addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget: self
                                                 action: @selector(buttonPushed:)]];
    }
}

#pragma mark Bottom bar button methods

//TODO: Pull bottomBarView and into own object (and its subviews - the back and forward view/buttons/methods, etc).

- (void)buttonPushed:(UITapGestureRecognizer *)sender
{
    TopMenuButtonView *tappedButton = (TopMenuButtonView *)sender.view;
    if (!tappedButton.enabled)return;

    switch (tappedButton.tag) {
        case BOTTOM_MENU_BUTTON_PREVIOUS:
            [self backButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_NEXT:
            [self forwardButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_SHARE:
            [self shareButtonPushed];
            break;
        default:
            break;
    }
}

- (void)shareButtonPushed
{
    [self showAlert:@"TODO: hook up share sheet!"];
    [self fadeAlert];
}

- (void)backButtonPushed
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

- (void)forwardButtonPushed
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

-(void)updateBottomBarButtonsEnabledState
{
    self.adjacentHistoryIDs = [self getAdjacentHistoryIDs];
    self.forwardButton.enabled = (self.adjacentHistoryIDs[@"after"]) ? YES : NO;
    self.backButton.enabled = (self.adjacentHistoryIDs[@"before"]) ? YES : NO;
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
