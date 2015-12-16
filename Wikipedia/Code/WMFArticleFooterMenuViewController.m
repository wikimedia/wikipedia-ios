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

@end
