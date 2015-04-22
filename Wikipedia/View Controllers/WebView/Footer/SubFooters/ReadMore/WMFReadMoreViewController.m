//  Created by Monte Hurd on 2/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFReadMoreViewController.h"
#import "PaddedLabel.h"
#import "SearchResultsController.h"
#import "WikipediaAppUtils.h"
#import "UIViewController+WMFChildViewController.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"

@interface WMFReadMoreViewController ()

@property (weak, nonatomic) IBOutlet PaddedLabel* titleLabel;
@property (weak, nonatomic) IBOutlet UIView* optionsContainerView;
@property (strong, nonatomic) SearchResultsController* searchSuggestionsController;

@end

@implementation WMFReadMoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.searchSuggestionsController = [SearchResultsController readMoreSearchResultsController];
    [self wmf_addChildController:self.searchSuggestionsController andConstrainToEdgesOfContainerView:self.optionsContainerView];

    self.titleLabel.padding = UIEdgeInsetsMake(0, 0, 20, 10);
    self.titleLabel.font    = [UIFont fontWithName:@"Times New Roman" size:26.0f * MENUS_SCALE_MULTIPLIER];
    [self updateLocalizedText];

    self.view.layer.cornerRadius = 2.0f * MENUS_SCALE_MULTIPLIER;
    self.view.clipsToBounds      = YES;

    [self adjustConstraintsScaleForViews:@[self.titleLabel, self.optionsContainerView]];
}

-(void)updateLocalizedText{
    self.titleLabel.text = MWCurrentArticleLanguageLocalizedString(@"article-read-more-title", @"Read more");
}

- (void)search {
    [self updateLocalizedText];
    self.searchSuggestionsController.searchString                 = self.searchString;
    self.searchSuggestionsController.articlesToExcludeFromResults = self.articlesToExcludeFromResults;
    [self.searchSuggestionsController search];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
