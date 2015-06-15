//
//  WMFSearchViewController.m
//  Wikipedia
//
//  Created by Corey Floyd on 6/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFSearchViewController.h"
#import "WMFArticleListCollectionViewController.h"

@interface WMFSearchViewController ()

@property (nonatomic, strong) WMFArticleListCollectionViewController* resultsListController;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation WMFSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListCollectionViewController class]]) {
        self.resultsListController = segue.destinationViewController;
    }
}


#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    
    [self.delegate searchControllerSearchDidStartSearching:self];
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    
    
    [self.delegate searchControllerSearchDidFinishSearching:self];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
}



@end
