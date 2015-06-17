
#import "WMFSearchViewController.h"
#import "WMFArticleListCollectionViewController.h"

#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"

#import "SearchDidYouMeanButton.h"

@interface WMFSearchViewController ()

@property (nonatomic, strong) WMFArticleListCollectionViewController* resultsListController;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIButton *searchSuggestionButton;

@property (nonatomic, strong) WMFSearchFetcher* fetcher;

@property (nonatomic, assign, readwrite) WMFSearchState state;

@end

@implementation WMFSearchViewController

- (NSString*)currentSearchTerm{
    return [(WMFSearchResults*)self.resultsListController.dataSource searchTerm];
}

- (void)updateSearchStateAndNotifyDelegate:(WMFSearchState)state{
    
    if(self.state == state){
        return;
    }
    
    self.state = state;

    [self.delegate searchController:self searchStateDidChange:self.state];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchSuggestionButton.hidden = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListCollectionViewController class]]) {
        self.resultsListController = segue.destinationViewController;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    
    [self updateSearchStateAndNotifyDelegate:WMFSearchStateActive];
    
    [self.searchBar setShowsCancelButton:YES animated:YES];
    
    self.fetcher = [[WMFSearchFetcher alloc] initWithSearchSite:self.searchSite dataStore:self.dataStore];
    
    if([self.searchBar.text length] > 2){
        
        if(![[self currentSearchTerm] isEqualToString:self.searchBar.text]){
            [self searchForSearchTerm:self.searchBar.text];
        }

    }else{
        
        self.resultsListController.dataSource = nil;
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    if(searchText.length > 2){
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if([searchText isEqualToString:self.searchBar.text]){
                [self searchForSearchTerm:searchText];
            }
        });
    }
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    
    [self updateSearchStateAndNotifyDelegate:WMFSearchStateInactive];

    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
}


#pragma mark - Search

- (void)searchForSearchTerm:(NSString*)searchTerm{
    
    [self.fetcher searchArticleTitlesForSearchTerm:searchTerm].then(^(WMFSearchResults* results){
        
        self.title = results.searchTerm;
        
        [self updateSearchButtonWithResults:results];
        
        self.resultsListController.dataSource = results;

    }).catch(^(NSError* error){
        
        NSLog(@"%@", [error description]);
    });
    
}

- (void)updateSearchButtonWithResults:(WMFSearchResults*)results{
    
//    if(![results noResults] && [results.searchSuggestion length]){
//        
//        self.searchSuggestionButton.hidden = NO;
//        
//        [self.searchSuggestionButton setTitle:[NSString stringWithFormat:@"%@:%@", MWLocalizedString(@"search-did-you-mean", nil), results.searchSuggestion] forState:UIControlStateNormal];
//        
//    }else{
//        
//        self.searchSuggestionButton.hidden = YES;
//    }

}


@end
