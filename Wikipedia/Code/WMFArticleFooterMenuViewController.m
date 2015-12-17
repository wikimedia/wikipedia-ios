//
//  WMFArticleFooterMenuViewController.m
//  Wikipedia
//
//  Created by Monte Hurd on 12/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleFooterMenuViewController.h"
#import "WMFIntrinsicSizeTableView.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"
#import "MWKArticle.h"
#import <SSDataSources/SSDataSources.h>
#import "NSDate+Utilities.h"
#import "WMFDisambiguationTitlesDataSource.h"
#import "WMFArticleListTableViewController.h"
#import "WMFTitlesSearchFetcher.h"

@interface WMFArticleFooterMenuViewController () <UITableViewDelegate>

@property (nonatomic, strong) SSArrayDataSource *footerDataSource;

@property (nonatomic, strong) IBOutlet WMFIntrinsicSizeTableView* tableView;
@property (nonatomic, strong) MWKArticle* article;

@end

@implementation WMFArticleFooterMenuViewController

- (instancetype)initWithArticle:(MWKArticle*)article {
    self = [super init];
    if (self) {
        self.article = article;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _footerDataSource = [[SSArrayDataSource alloc] initWithItems:[self getData]];
    
    self.footerDataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, NSDictionary *dictionary, UITableView *tableView, NSIndexPath *indexPath) {
        [cell wmf_makeCellDividerBeEdgeToEdge];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.tintColor = [UIColor grayColor];
        cell.textLabel.text = dictionary[@"text"];
        cell.imageView.image = [UIImage imageNamed:dictionary[@"image"]];
    };
    
    self.footerDataSource.tableActionBlock = ^BOOL(SSCellActionType action, UITableView *tableView, NSIndexPath *indexPath) {
        return NO;
    };
    
    self.footerDataSource.tableView = self.tableView;
}

-(NSArray*)getData {
    NSMutableArray *data =
    [NSMutableArray arrayWithObjects:
     @{@"text": [MWLocalizedString(@"page-read-in-other-languages", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%d", self.article.languagecount]], @"image": @"language"},
     @{@"text": [MWLocalizedString(@"page-last-edited", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%ld", [[NSDate date] daysAfterDate:self.article.lastmodified]]], @"image": @"edit-history"},
     nil];
    
    if (self.article.pageIssues) {
        [data addObject: @{@"text": MWLocalizedString(@"page-issues", nil), @"image": @"warnings"}];
    }
    
    if (self.article.disambiguationTitles) {
        [data addObject: @{@"text": MWLocalizedString(@"page-similar-titles", nil), @"image": @"similar-pages"}];
    }
    return data;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    //TODO:
    // -update data model per and only call this when similar pages is tapped
    // -hook up other item taps to show respective interfaces
    [self showDisambiguationItems];
}

-(void) showDisambiguationItems {
    WMFDisambiguationTitlesDataSource* dataSource = [[WMFDisambiguationTitlesDataSource alloc] initWithTitles:self.article.disambiguationTitles site:self.article.site fetcher:[[WMFTitlesSearchFetcher alloc] init]];
    
    WMFArticleListTableViewController* articleListVC = [[WMFArticleListTableViewController alloc] init];
    articleListVC.dataStore  = self.dataStore;
    articleListVC.dataSource = dataSource;
    [dataSource fetch];
    [self.navigationController pushViewController:articleListVC animated:YES];
}

@end
