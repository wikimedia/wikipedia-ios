@import UIKit;
@class WMFShareFunnel, MWKArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFShareOptionsController : NSObject

@property (nonatomic, strong, readonly) MWKArticle *article;
@property (nonatomic, strong, readonly) WMFShareFunnel *funnel;
@property (nonatomic, getter=isActive, readonly) BOOL active;

/**
 * Initialize a new instance with an article and an optional snippet.
 *
 * @param article           The article the snippet is derived from.
 * @param funnel            The funnel to use to log events.
 */
- (instancetype)initWithArticle:(MWKArticle *)article
                    shareFunnel:(WMFShareFunnel *)funnel NS_DESIGNATED_INITIALIZER;

/**
 * Present the share options with the specified snippet, in the given viewcontroller, from the given button item.
 *
 * @param snippet           The snippet to share.
 * @param viewController    The view controller that will present the menus.
 * @param item              The item that will serve as the origin for the menu (i.e. a popover arrow).
 *
 * @note Truncating `snippet` is not necessary, as it's done internally by the share view's `UILabel`.
 */
- (void)presentShareOptionsWithSnippet:(NSString *)snippet inViewController:(UIViewController *)viewController fromBarButtonItem:(UIBarButtonItem *)item;

@end

NS_ASSUME_NONNULL_END
