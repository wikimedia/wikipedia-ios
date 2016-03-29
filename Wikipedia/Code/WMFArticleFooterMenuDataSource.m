#import "WMFArticleFooterMenuDataSource.h"
#import "WMFArticleFooterMenuItem.h"
#import "MWKArticle.h"
#import "NSDate+Utilities.h"
#import "WMFArticleFooterMenuCell.h"
#import "MWKTitle.h"
#import <Tweaks/FBTweakInline.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticleFooterMenuDataSource

- (instancetype)initWithArticle:(nullable MWKArticle*)article {
    self = [super initWithItems:nil];
    if (self) {
        self.cellClass          = [WMFArticleFooterMenuCell class];
        self.cellConfigureBlock = ^(WMFArticleFooterMenuCell* cell, WMFArticleFooterMenuItem* menuItem, UITableView* tableView, NSIndexPath* indexPath) {
            cell.title     = menuItem.title;
            cell.subTitle  = menuItem.subTitle;
            cell.imageName = menuItem.imageName;
        };

        self.tableActionBlock = ^BOOL (SSCellActionType action, UITableView* tableView, NSIndexPath* indexPath) {
            return NO;
        };

        self.article = article;
    }
    return self;
}

- (void)setArticle:(nullable MWKArticle*)article {
    if (WMF_EQUAL(self.article, isEqualToArticle:, article)) {
        return;
    }
    _article = article;
    [self updateItemsForArticle:article];
}

- (void)updateItemsForArticle:(nullable MWKArticle*)article {
    if (!article) {
        [self removeAllItems];
        return;
    }

    WMFArticleFooterMenuItem* (^ makeItem)(WMFArticleFooterMenuItemType, NSString*, NSString*, NSString*) = ^WMFArticleFooterMenuItem*(WMFArticleFooterMenuItemType type, NSString* title, NSString* subTitle, NSString* imageName) {
        return [[WMFArticleFooterMenuItem alloc] initWithType:type
                                                        title:title
                                                     subTitle:subTitle
                                                    imageName:imageName];
    };

    NSMutableArray<WMFArticleFooterMenuItem*>* menuItems = [NSMutableArray arrayWithCapacity:4];

    if (article.languagecount > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeLanguages,
                                      [MWSiteLocalizedString(article.title.site, @"page-read-in-other-languages", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%d", article.languagecount]],
                                      nil, @"footer-switch-language")];
    }

    NSDate *lastModified = article.lastmodified ? article.lastmodified : [NSDate date];
    
    if (FBTweakValue(@"Article", @"Article Metadata Footer", @"Show last edit timestamp", NO)) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeLastEdited,
                                      [lastModified mediumString],
                                      MWSiteLocalizedString(article.title.site, @"page-edit-history", nil),
                                      @"footer-edit-history")];
    } else {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeLastEdited,
                                      [MWSiteLocalizedString(article.title.site, @"page-last-edited", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%ld", (long)[[NSDate date] daysAfterDate:lastModified]]],
                                      MWSiteLocalizedString(article.title.site, @"page-edit-history", nil),
                                      @"footer-edit-history")];
    }

    if (article.pageIssues.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypePageIssues,
                                      MWSiteLocalizedString(article.title.site, @"page-issues", nil),
                                      nil,
                                      @"footer-warnings")];
    }

    if (article.disambiguationTitles.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeDisambiguation,
                                      MWSiteLocalizedString(article.title.site, @"page-similar-titles", nil),
                                      nil,
                                      @"footer-similar-pages")];
    }
    [self updateItems:menuItems];
}

@end

NS_ASSUME_NONNULL_END
