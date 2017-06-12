@import UIKit;

/**
 * View controller which displays "pages" of content using a collection view.
 */
@interface WMFPageCollectionViewController : UICollectionViewController

/**
 *  The page which is currently being displayed in the receiver.
 *
 *  @note Setting this value before the view is loaded will defer bounds checking until @c viewDidLoad, which could
 *        result in crashes which are more difficult to debug.
 */
@property (nonatomic) NSUInteger currentPage;

- (void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated;

///
/// Subclass Overrides
///

/**
 *  Called whenever the page is changed programmatically or by the user scrolling.
 *
 *  Override this method to do additional UI updates or logic when the page changes.
 *
 *  @warning Your implementation must call @c super.
 *
 *  @param page The new value of current page.
 */
- (void)primitiveSetCurrentPage:(NSUInteger)page;

/**
 * Flag which dictates whether or not the current `currentPage` has been applied.
 *
 * Check this whenever doing work while view size is transitioning or device is rotating, as
 * `WMFPageCollectionViewController` will set/reset this flag as necessary to ensure `currentPage` is maintained
 * through a transition.
 */
@property (nonatomic) BOOL didApplyCurrentPage;

/**
 *  Method which is invoked to update the collection view to display the current page.
 *
 *  Subclasses can override this to perform additional updates when the page changes.
 *
 *  @note Subclasses must invoke @c super.
 *
 *  @param animated Whether or not the transition is animated.
 */
- (void)applyCurrentPage:(BOOL)animated;

@end
