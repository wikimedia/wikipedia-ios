#import "WMFArticleFooterMenuDataSource.h"
#import "WMFArticleFooterMenuItem.h"
#import "MWKArticle.h"
#import "NSDate+Utilities.h"
#import "WMFArticleFooterMenuCell.h"

@interface WMFArticleFooterMenuDataSource ()

@property (nonatomic, strong, readwrite) MWKArticle* article;

@end

@implementation WMFArticleFooterMenuDataSource

- (instancetype)initWithArticle:(MWKArticle*)article {
    self = [super initWithItems:[self menuItemsForArticle:article]];
    if (self) {
        self.article            = article;
        self.cellClass          = [WMFArticleFooterMenuCell class];
        self.cellConfigureBlock = ^(WMFArticleFooterMenuCell *cell, WMFArticleFooterMenuItem *menuItem, UITableView *tableView, NSIndexPath *indexPath) {
            cell.textLabel.text = menuItem.title;
            cell.detailTextLabel.text = menuItem.subTitle;
            cell.imageView.image = [UIImage imageNamed:menuItem.imageName];
        };
        
        self.tableActionBlock = ^BOOL(SSCellActionType action, UITableView *tableView, NSIndexPath *indexPath) {
            return NO;
        };
    }
    return self;
}

-(NSArray<WMFArticleFooterMenuItem*>*)menuItemsForArticle:(MWKArticle*)article {
    
    WMFArticleFooterMenuItem* (^makeItem)(WMFArticleFooterMenuItemType, NSString*, NSString*, NSString*) = ^WMFArticleFooterMenuItem*(WMFArticleFooterMenuItemType type, NSString* title, NSString* subTitle, NSString* imageName) {
        return [[WMFArticleFooterMenuItem alloc] initWithType:type
                                                        title:title
                                                     subTitle:subTitle
                                                    imageName:imageName];
    };
    
    NSMutableArray* menuItems =
    [NSMutableArray arrayWithObjects:
     makeItem(WMFArticleFooterMenuItemTypeLanguages,
              [MWLocalizedString(@"page-read-in-other-languages", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%d", article.languagecount]],
              nil, @"footer-switch-language"),
     makeItem(WMFArticleFooterMenuItemTypeLastEdited,
              [MWLocalizedString(@"page-last-edited", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%ld", [[NSDate date] daysAfterDate:article.lastmodified]]],
              MWLocalizedString(@"page-edit-history", nil),
              @"footer-edit-history"),
     nil
     ];
    
    if (article.pageIssues.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypePageIssues,
                                      MWLocalizedString(@"page-issues", nil),
                                      nil,
                                      @"footer-warnings")];
    }
    
    if (article.disambiguationTitles.count > 0) {
        [menuItems addObject:makeItem(WMFArticleFooterMenuItemTypeDisambiguation,
                                      MWLocalizedString(@"page-similar-titles", nil),
                                      nil,
                                      @"footer-similar-pages")];
    }
    
    return menuItems;
}

@end
