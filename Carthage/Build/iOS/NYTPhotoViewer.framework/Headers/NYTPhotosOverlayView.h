//
//  NYTPhotosOverlayView.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/17/15.
//
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  A view that overlays an `NYTPhotosViewController`, and houses the left and right bar button items, a title, and a caption view.
 */
@interface NYTPhotosOverlayView : UIView

/**
 *  The internal navigation bar used to set the bar button items and title of the overlay.
 */
@property (nonatomic, readonly) UINavigationBar *navigationBar;

/**
 *  The title of the overlay. Centered between the left and right bar button items.
 */
@property (nonatomic, copy, nullable) NSString *title;

/**
 *  The attributes of the overlay's title.
 */
@property(nonatomic, copy, nullable) NSDictionary <NSString *, id> *titleTextAttributes;

/**
 *  The bar button item appearing at the top left of the overlay.
 */
@property (nonatomic, nullable) UIBarButtonItem *leftBarButtonItem;

/**
 *  The bar button items appearing at the top left of the overlay.
 */
@property (nonatomic, copy, nullable) NSArray <UIBarButtonItem *> *leftBarButtonItems;

/**
 *  The bar button item appearing at the top right of the overlay.
 */
@property (nonatomic, nullable) UIBarButtonItem *rightBarButtonItem;

/**
 *  The bar button items appearing at the top right of the overlay.
 */
@property (nonatomic, copy, nullable) NSArray <UIBarButtonItem *> *rightBarButtonItems;

/**
 *  A view representing the caption for the photo, which will be set to full width and locked to the bottom. Can be any `UIView` object, but is expected to respond to `intrinsicContentSize` appropriately to calculate height.
 */
@property (nonatomic, nullable) UIView *captionView;

/**
 *  Whether the `captionView` should respect the safe area or not
 */
@property (nonatomic) BOOL captionViewRespectsSafeArea;

@end

NS_ASSUME_NONNULL_END
