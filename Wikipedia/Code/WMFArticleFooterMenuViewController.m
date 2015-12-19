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
#import "WMFArticleListTableViewController.h"
#import "WMFArticlePreviewFetcher.h"
#import "WMFArticleFooterMenuItem.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "PageHistoryViewController.h"
#import "LanguagesViewController.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageLink.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFDisambiguationPagesViewController.h"
#import "WMFPageIssuesViewController.h"

@interface WMFArticleFooterMenuViewController () <UITableViewDelegate, LanguageSelectionDelegate>

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
        cell.imageView.contentMode = UIViewContentModeCenter;
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
    
    NSMutableArray* menuItems =
    [NSMutableArray arrayWithObjects:
     makeItem(WMFArticleFooterMenuItemTypeLanguages,
              [MWLocalizedString(@"page-read-in-other-languages", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%d", self.article.languagecount]],
              @"footer-switch-language"),
     makeItem(WMFArticleFooterMenuItemTypeLastEdited,
              [MWLocalizedString(@"page-last-edited", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%ld", [[NSDate date] daysAfterDate:self.article.lastmodified]]],
              @"footer-edit-history"),
     nil
     ];
    
    if (self.article.pageIssues.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypePageIssues,
                                      MWLocalizedString(@"page-issues", nil),
                                      @"footer-warnings")];
    }
    
    if (self.article.disambiguationTitles.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeDisambiguation,
                                      MWLocalizedString(@"page-similar-titles", nil),
                                      @"footer-similar-pages")];
    }
    
    return menuItems;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleFooterMenuItem*selectedItem = [self menuItemForIndexPath:indexPath];
    switch (selectedItem.type) {
        case WMFArticleFooterMenuItemTypeLanguages:
            [self showLanguages];
            break;
        case WMFArticleFooterMenuItemTypeLastEdited:
            [self showEditHistory];
            break;
        case WMFArticleFooterMenuItemTypePageIssues:
            [self showPageIssues];
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
    WMFDisambiguationPagesViewController* articleListVC = [[WMFDisambiguationPagesViewController alloc] initWithArticle:self.article dataStore:self.dataStore];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:articleListVC] animated:YES completion:^{
    }];
}

- (void)showEditHistory {
    PageHistoryViewController* editHistoryVC = [PageHistoryViewController wmf_initialViewControllerFromClassStoryboard];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:editHistoryVC] animated:YES completion:nil];
}

- (void)showLanguages {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.articleTitle              = self.article.title;
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:language.title discoveryMethod:MWKHistoryDiscoveryMethodLink dataStore:self.dataStore];
    }];
}

-(void)showPageIssues {
    WMFPageIssuesViewController *issuesVC = [[WMFPageIssuesViewController alloc] initWithStyle:UITableViewStyleGrouped];
    issuesVC.dataSource = [[SSArrayDataSource alloc] initWithItems:self.article.pageIssues];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:issuesVC] animated:YES completion:nil];
}

@end
