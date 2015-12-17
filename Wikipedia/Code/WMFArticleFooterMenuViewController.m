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
#import "WMFArticleFooterMenuItem.h"

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
    
    _footerDataSource = [[SSArrayDataSource alloc] initWithItems:[self getMenuItemData]];
    
    self.footerDataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, WMFArticleFooterMenuItem *menuItem, UITableView *tableView, NSIndexPath *indexPath) {
        [cell wmf_makeCellDividerBeEdgeToEdge];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.tintColor = [UIColor grayColor];
        cell.textLabel.text = menuItem.title;
        cell.imageView.image = [UIImage imageNamed:menuItem.imageName];
    };
    
    self.footerDataSource.tableActionBlock = ^BOOL(SSCellActionType action, UITableView *tableView, NSIndexPath *indexPath) {
        return NO;
    };
    
    self.footerDataSource.tableView = self.tableView;
}

-(NSArray<WMFArticleFooterMenuItem*>*)getMenuItemData {
    
    WMFArticleFooterMenuItem* (^makeItem)(WMFArticleFooterMenuItemType, NSString*, NSString*) = ^WMFArticleFooterMenuItem*(WMFArticleFooterMenuItemType type, NSString* title, NSString* imageName) {
        return [[WMFArticleFooterMenuItem alloc] initWithType:type
                                                        title:title
                                                    imageName:imageName];
    };
    
    return @[
             makeItem(WMFArticleFooterMenuItemTypeLanguages,
                      [MWLocalizedString(@"page-read-in-other-languages", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%d", self.article.languagecount]],
                      @"language"),
             makeItem(WMFArticleFooterMenuItemTypeLastEdited,
                      [MWLocalizedString(@"page-last-edited", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%ld", [[NSDate date] daysAfterDate:self.article.lastmodified]]],
                      @"edit-history"),
             makeItem(WMFArticleFooterMenuItemTypePageIssues,
                      MWLocalizedString(@"page-issues", nil),
                      @"warnings"),
             makeItem(WMFArticleFooterMenuItemTypeDisambiguation,
                      MWLocalizedString(@"page-similar-titles", nil),
                      @"similar-pages")
             ];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleFooterMenuItem*selectedItem = [self menuItemForIndexPath:indexPath];
    switch (selectedItem.type) {
        case WMFArticleFooterMenuItemTypeLanguages:
            
            break;
        case WMFArticleFooterMenuItemTypeLastEdited:
            
            break;
        case WMFArticleFooterMenuItemTypePageIssues:
            
            break;
        case WMFArticleFooterMenuItemTypeDisambiguation:
            [self showDisambiguationItems];
            break;
    }
}

-(WMFArticleFooterMenuItem*)menuItemForIndexPath:(NSIndexPath*)indexPath {
    return self.footerDataSource.allItems[indexPath.row];
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
