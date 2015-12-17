
#import <Mantle/Mantle.h>

typedef NS_ENUM (NSUInteger, WMFArticleFooterMenuItemType){
    WMFArticleFooterMenuItemTypeLanguages,
    WMFArticleFooterMenuItemTypeLastEdited,
    WMFArticleFooterMenuItemTypePageIssues,
    WMFArticleFooterMenuItemTypeDisambiguation
};

@interface WMFArticleFooterMenuItem : MTLModel

@property (nonatomic, copy, readonly) NSString* title;

@property (nonatomic, copy, readonly) NSString* imageName;

@property (nonatomic, assign, readonly) WMFArticleFooterMenuItemType type;

- (instancetype)initWithType:(WMFArticleFooterMenuItemType)type
                       title:(NSString*)title
                   imageName:(NSString*)imageName;
@end
