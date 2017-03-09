#import "WMFArticleFooterMenuDataSource.h"
#import "WMFArticleFooterMenuItem.h"
#import "MWKArticle.h"
#import "WMFArticleFooterMenuCell.h"
#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakInline.h>
#endif
NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticleFooterMenuDataSource

- (instancetype)initWithArticle:(nullable MWKArticle *)article {
    self = [super initWithItems:nil];
    if (self) {
        self.cellClass = [WMFArticleFooterMenuCell class];
        self.cellConfigureBlock = ^(WMFArticleFooterMenuCell *cell, WMFArticleFooterMenuItem *menuItem, UITableView *tableView, NSIndexPath *indexPath) {
            cell.title = menuItem.title;
            cell.subTitle = menuItem.subTitle;
            cell.imageName = menuItem.imageName;
        };

        self.tableActionBlock = ^BOOL(SSCellActionType action, UITableView *tableView, NSIndexPath *indexPath) {
            return NO;
        };

        self.article = article;
    }
    return self;
}

- (void)setArticle:(nullable MWKArticle *)article {
    if (WMF_EQUAL(self.article, isEqualToArticle:, article)) {
        return;
    }
    _article = article;
    [self updateItemsForArticle:article];
}

- (void)updateItemsForArticle:(nullable MWKArticle *)article {
    if (!article) {
        [self removeAllItems];
        return;
    }

    WMFArticleFooterMenuItem * (^makeItem)(WMFArticleFooterMenuItemType, NSString *, NSString *, NSString *) = ^WMFArticleFooterMenuItem *(WMFArticleFooterMenuItemType type, NSString *title, NSString *subTitle, NSString *imageName) {
        return [[WMFArticleFooterMenuItem alloc] initWithType:type
                                                        title:title
                                                     subTitle:subTitle
                                                    imageName:imageName];
    };

    NSMutableArray<WMFArticleFooterMenuItem *> *menuItems = [NSMutableArray arrayWithCapacity:4];

    if (article.hasMultipleLanguages) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeLanguages,
                                      [MWSiteLocalizedString(article.url, @"page-read-in-other-languages", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                                                          withString:[NSString stringWithFormat:@"%d", article.languagecount]],
                                      nil, @"footer-switch-language")];
    }
    
    if (CLLocationCoordinate2DIsValid(article.coordinate)) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeCoordinate,
                                      MWSiteLocalizedString(article.url, @"page-location", nil),
                                      nil,
                                      @"footer-location")];
        
    }

    NSDate *lastModified = article.lastmodified ? article.lastmodified : [NSDate date];

    NSInteger days = [[NSCalendar wmf_gregorianCalendar] wmf_daysFromDate:lastModified toDate:[NSDate date]];
    [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeLastEdited,
                                  [MWSiteLocalizedString(article.url, @"page-last-edited", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                                          withString:[NSString stringWithFormat:@"%ld", (long)days]],
                                  MWSiteLocalizedString(article.url, @"page-edit-history", nil),
                                  @"footer-edit-history")];

    if (article.pageIssues.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypePageIssues,
                                      MWSiteLocalizedString(article.url, @"page-issues", nil),
                                      nil,
                                      @"footer-warnings")];
    }

    if (article.disambiguationURLs.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeDisambiguation,
                                      MWSiteLocalizedString(article.url, @"page-similar-titles", nil),
                                      nil,
                                      @"footer-similar-pages")];
    }
    
    
    [self updateItems:menuItems];
}

@end

NS_ASSUME_NONNULL_END
