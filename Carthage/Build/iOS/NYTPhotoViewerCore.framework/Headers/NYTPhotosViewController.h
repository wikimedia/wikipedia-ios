//
//  NYTPhotosViewController.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/10/15.
//  Copyright (c) 2015 NYTimes. All rights reserved.
//

@import UIKit;

@class NYTPhotosOverlayView;

@protocol NYTPhoto;
@protocol NYTPhotosViewControllerDelegate;
@protocol NYTPhotoViewerDataSource;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification name issued when this `NYTPhotosViewController` navigates to a different photo.
 *
 *  Includes the `NYTPhotosViewController` instance, as the notification's object.
 */
extern NSString * const NYTPhotosViewControllerDidNavigateToPhotoNotification;

extern NSString * const NYTPhotosViewControllerDidNavigateToInterstitialViewNotification;

/**
 *  Notification name issued when this `NYTPhotosViewController` is about to be dismissed.
 *
 *  Includes the `NYTPhotosViewController` instance, as the notification's object.
 */
extern NSString * const NYTPhotosViewControllerWillDismissNotification;

/**
 *  Notification name issued when this `NYTPhotosViewController` has been dismissed.
 *
 *  Includes the `NYTPhotosViewController` instance, as the notification's object.
 */
extern NSString * const NYTPhotosViewControllerDidDismissNotification;

@interface NYTPhotosViewController : UIViewController

/**
 *  The pan gesture recognizer used for panning to dismiss the photo. Disable to stop the pan-to-dismiss behavior.
 */
@property (nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

/**
 *  The tap gesture recognizer used to hide the overlay, including the caption, left and right bar button items, and title, all at once. Disable to always show the overlay.
 */
@property (nonatomic, readonly) UITapGestureRecognizer *singleTapGestureRecognizer;

/**
 *  The internal page view controller used for swiping horizontally, photo to photo. Created during `viewDidLoad`.
 */
@property (nonatomic, readonly, nullable) UIPageViewController *pageViewController;

/**
 *  The data source underlying this PhotosViewController.
 *
 *  After setting a new data source, you must call `-reloadPhotosAnimated:`.
 */
@property (nonatomic, weak, nullable) id <NYTPhotoViewerDataSource> dataSource;

/**
 *  The object conforming to `NYTPhoto` that is currently being displayed by the `pageViewController`.
 *
 *  This photo will be one of the photos from the data source.
 */
@property (nonatomic, readonly, nullable) id <NYTPhoto> currentlyDisplayedPhoto;

/**
 *  The overlay view displayed over photos. Created during `viewDidLoad`.
 */
@property (nonatomic, readonly, nullable) NYTPhotosOverlayView *overlayView;

/**
 *  The left bar button item overlaying the photo.
 */
@property (nonatomic, nullable) UIBarButtonItem *leftBarButtonItem;

/**
 *  The left bar button items overlaying the photo.
 */
@property (nonatomic, copy, nullable) NSArray <UIBarButtonItem *> *leftBarButtonItems;

/**
 *  The right bar button item overlaying the photo.
 */
@property (nonatomic, nullable) UIBarButtonItem *rightBarButtonItem;

/**
 *  The right bar button items overlaying the photo.
 */
@property (nonatomic, copy, nullable) NSArray <UIBarButtonItem *> *rightBarButtonItems;

/**
 *  The object that acts as the delegate of the `NYTPhotosViewController`.
 */
@property (nonatomic, weak, nullable) id <NYTPhotosViewControllerDelegate> delegate;

/**
 *  Initializes a `PhotosViewController` with the given data source, initially displaying the first photo in the data source.
 *
 *  @param dataSource The data source underlying this photo viewer.
 *
 *  @return A fully initialized `PhotosViewController` instance.
 */
- (instancetype)initWithDataSource:(id <NYTPhotoViewerDataSource>)dataSource;

/**
 *  Initializes a `PhotosViewController` with the given data source and delegate, initially displaying the photo at the given index in the data source.
 *
 *  @param dataSource        The data source underlying this photo viewer.
 *  @param initialPhotoIndex The photo to display initially. If outside the bounds of the data source, the first photo from the data source will be displayed.
 *  @param delegate          The delegate for this `NYTPhotosViewController`.
 *
 *  @return A fully initialized `PhotosViewController` instance.
 */
- (instancetype)initWithDataSource:(id <NYTPhotoViewerDataSource>)dataSource initialPhotoIndex:(NSInteger)initialPhotoIndex delegate:(nullable id <NYTPhotosViewControllerDelegate>)delegate;

/**
 *  Initializes a `PhotosViewController` with the given data source and delegate, initially displaying the given photo.
 *
 *  @param dataSource   The data source underlying this photo viewer.
 *  @param initialPhoto The photo to display initially. Must be a member of the data source. If `nil` or not a member of the data source, the first photo from the data source will be displayed.
 *  @param delegate     The delegate for this `NYTPhotosViewController`.
 *
 *  @return A fully initialized `PhotosViewController` instance.
 */
- (instancetype)initWithDataSource:(id <NYTPhotoViewerDataSource>)dataSource initialPhoto:(nullable id <NYTPhoto>)initialPhoto delegate:(nullable id <NYTPhotosViewControllerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

/**
 *  Displays the specified photo. Can be called before the view controller is displayed. Calling with a photo not contained within the data source has no effect.
 *
 *  @param photo    The photo to make the currently displayed photo.
 *  @param animated Whether to animate the transition to the new photo.
 */
- (void)displayPhoto:(nullable id <NYTPhoto>)photo animated:(BOOL)animated;

/**
 *  Informs the photo viewer that the photo in the data source at this index has changed.
 *
 *  In response, the photo viewer will retrieve and update the overlay information and the photo itself.
 *
 *  This method has no effect if the given index is out of bounds in the data source.
 *
 *  @param photoIndex The index of the photo which changed in the data source.
 */
- (void)updatePhotoAtIndex:(NSInteger)photoIndex;

/**
 *  Informs the photo viewer that the given photo in the data source has changed.
 *
 *  In response, the photo viewer will retrieve and update the overlay information and the photo itself.
 *
 *  This method has no effect if the photo doesn't exist in the data source.
 *
 *  @param photo The photo which changed in the data source.
 */
- (void)updatePhoto:(id<NYTPhoto>)photo;

/**
 *  Tells the photo viewer to reload all data from its data source.
 *
 *  @param animated Whether any resulting transitions should be animated.
 */
- (void)reloadPhotosAnimated:(BOOL)animated;

@end

/**
 *  A protocol of entirely optional methods called for view-related configuration and lifecycle events by an `NYTPhotosViewController` instance.
 */
@protocol NYTPhotosViewControllerDelegate <NSObject>

@optional

/**
 *  Called when a new photo is displayed through a swipe gesture.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                The photo object that was just displayed.
 *  @param photoIndex           The index of the photo that was just displayed.
 */
- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToPhoto:(id <NYTPhoto>)photo atIndex:(NSUInteger)photoIndex;

/**
 *  Called when a new interstitial view is displayed through a swipe gesture.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param view                 The view that was just displayed.
 *  @param index                The index of the view that was just displayed.
 */
- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToInterstialView:(UIView *)view atIndex:(NSUInteger)index;

/**
 *  Called immediately before the `NYTPhotosViewController` is about to start a user-initiated dismissal.
 *  This will be the beginning of the interactive panning to dismiss, if it is enabled and performed.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 */
- (void)photosViewControllerWillDismiss:(NYTPhotosViewController *)photosViewController;

/**
 *  Called immediately after the photos view controller has been dismissed by the user.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 */
- (void)photosViewControllerDidDismiss:(NYTPhotosViewController *)photosViewController;

/**
 *  Returns a view to display over a photo, full width, locked to the bottom, representing the caption for the photo.
 *
 *  Can be any `UIView` object, but the view returned is expected to respond to `intrinsicContentSize` appropriately to calculate height.
 *
 *  @note Your implementation can get caption information from the appropriate properties on the given `NYTPhoto`.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                The photo object over which to display the caption view.
 *
 *  @return A view to display as the caption for the photo. Return `nil` to show a default view generated from the caption properties on the photo object.
 */
- (nullable UIView *)photosViewController:(NYTPhotosViewController *)photosViewController captionViewForPhoto:(id <NYTPhoto>)photo;

/**
 *  Returns whether the caption view should respect the safe area.
 *
 * @note If this method is not implemented it will default to `YES`.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                The photo object over which to display the caption view.
 *
 *  @return A `BOOL` indicating whether the caption view should respect the safe area for the given photo or not.
 */
- (BOOL)photosViewController:(NYTPhotosViewController *)photosViewController captionViewRespectsSafeAreaForPhoto:(id <NYTPhoto>)photo;

/**
 *  Returns a string to display as the title in the navigation-bar area for a photo.
 *
 *  This small area of the screen is not intended to display a caption or similar information about the photo itself. (NYTPhotoViewer is designed to provide this information in the caption view, and as such the `NYTPhoto` protocol provides properties for a title, summary, and credit for each photo.) Instead, consider using this delegate method to customize how your app displays the user's progress through a set of photos.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                The photo object for which to display the title.
 *  @param photoIndex           The index of the photo.
 *  @param totalPhotoCount      The number of photos being displayed by the photo viewer, or `nil` if the total number of photos is not known. The given number packages an `NSInteger`.
 *
 *  @return The text to display as the navigation-item title for the given photo. Return `nil` to show a default title like "1 of 4" indicating progress in a slideshow, or an empty string to hide this text entirely.
 */
- (nullable NSString *)photosViewController:(NYTPhotosViewController *)photosViewController titleForPhoto:(id <NYTPhoto>)photo atIndex:(NSInteger)photoIndex totalPhotoCount:(nullable NSNumber *)totalPhotoCount;

/**
 *  Returns a view to display while a photo is loading. Can be any `UIView` object, but is expected to respond to `sizeToFit` appropriately. This view will be sized and centered in the blank area, and hidden when the photo image or its placeholder is loaded.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                The photo object over which to display the activity view.
 *
 *  @return A view to display while the photo is loading. Return `nil` to show a default white `UIActivityIndicatorView`.
 */
- (nullable UIView *)photosViewController:(NYTPhotosViewController *)photosViewController loadingViewForPhoto:(id <NYTPhoto>)photo;

/**
 *  Returns the view from which to animate for a given object conforming to the `NYTPhoto` protocol.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                The photo for which the animation will occur.
 *
 *  @return The view to animate out of or into for the given photo.
 */
- (nullable UIView *)photosViewController:(NYTPhotosViewController *)photosViewController referenceViewForPhoto:(id <NYTPhoto>)photo;

/**
*  Returns the maximum zoom scale for a given object conforming to the `NYTPhoto` protocol.
*
*  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
*  @param photo                The photo for which the maximum zoom scale is requested.
*
*  @return The maximum zoom scale for the given photo.
*/
- (CGFloat)photosViewController:(NYTPhotosViewController *)photosViewController maximumZoomScaleForPhoto:(id <NYTPhoto>)photo;

/**
 *  Called when a photo is long pressed.
 *
 *  @param photosViewController       The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                      The photo being displayed that was long pressed.
 *  @param longPressGestureRecognizer The gesture recognizer that detected the long press.
 *
 *  @return `YES` if the long press was handled by the client, `NO` if the default `UIMenuController` with a Copy action is desired.
 */
- (BOOL)photosViewController:(NYTPhotosViewController *)photosViewController handleLongPressForPhoto:(id <NYTPhoto>)photo withGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer;

/**
 *  Called when the action button is tapped.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param photo                The photo being displayed when the action button was tapped.
 *
 *  @return `YES` if the action button tap was handled by the client, `NO` if the default `UIActivityViewController` is desired.
 */
- (BOOL)photosViewController:(NYTPhotosViewController *)photosViewController handleActionButtonTappedForPhoto:(id <NYTPhoto>)photo;

/**
 *  Called after the default `UIActivityViewController` is presented and successfully completes an action with a specified activity type.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param activityType         The activity type that was successfully shared.
 */
- (void)photosViewController:(NYTPhotosViewController *)photosViewController actionCompletedWithActivityType:(nullable NSString *)activityType;

/**
 *  called when an `NYTInterstitialViewController` is created but before it is displayed. Returns the view to display as an interstitial view.
 *
 *  @param photosViewController The `NYTPhotosViewController` instance that sent the delegate message.
 *  @param index                The index in the page view controller where the view will be displayed.
 *
 *  @return A `UIView`.
 */
- (nullable UIView *)photosViewController:(NYTPhotosViewController *)photosViewController interstitialViewAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
