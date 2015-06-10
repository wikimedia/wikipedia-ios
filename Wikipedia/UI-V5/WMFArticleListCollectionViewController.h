
#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, WMFArticleListType) {
    WMFArticleListTypeSaved,
    WMFArticleListTypeSearch,
    WMFArticleListTypeHistory
};

@interface WMFArticleListCollectionViewController : UICollectionViewController


@property (nonatomic, assign, readonly) WMFArticleListType listType;

/**
 *  Set the list type, optionally animating the change
 *
 *  @param type     The type of list to display
 *  @param animated Whether the change should be animated
 */
- (void)setListType:(WMFArticleListType)type animated:(BOOL)animated;

/**
 *  Must be set to display data
 */
@property (nonatomic, strong) MWKUserDataStore* userDataStore;



@end
