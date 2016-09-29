//
//  NYTPhotoViewController.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/11/15.
//
//

@import UIKit;
#import "NYTPhotoContainer.h"

@class NYTScalingImageView;

@protocol NYTPhoto;
@protocol NYTPhotoViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 *  `NYTPhotoViewController` observes this notification. It expects an `id <NYTPhoto>` object as the object of the notification.
 */
extern NSString * const NYTPhotoViewControllerPhotoImageUpdatedNotification;

/**
 *  The view controller controlling the display of a single photo object.
 */
@interface NYTPhotoViewController : UIViewController <NYTPhotoContainer>

/**
 *  The internal scaling image view used to display the photo.
 */
@property (nonatomic, readonly) NYTScalingImageView *scalingImageView;

/**
 *  The internal activity view shown while the image is loading. Set from the initializer.
 */
@property (nonatomic, readonly, nullable) UIView *loadingView;

/**
 *  The gesture recognizer used to detect the double tap gesture used for zooming on photos.
 */
@property (nonatomic, readonly) UITapGestureRecognizer *doubleTapGestureRecognizer;

/**
 *  The object that acts as the photo view controller's delegate.
 */
@property (nonatomic, weak, nullable) id <NYTPhotoViewControllerDelegate> delegate;

/**
 *  The designated initializer that takes the photo and activity view.
 *
 *  @param photo              The photo object that this view controller manages.
 *  @param loadingView        The view to display while the photo's image loads. This view will be hidden when the image loads.
 *  @param notificationCenter The notification center on which to observe the `NYTPhotoViewControllerPhotoImageUpdatedNotification`.
 *
 *  @return A fully initialized object.
 */
- (instancetype)initWithPhoto:(nullable id <NYTPhoto>)photo loadingView:(nullable UIView *)loadingView notificationCenter:(nullable NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

@end

@protocol NYTPhotoViewControllerDelegate <NSObject>

@optional

/**
 *  Called when a long press is recognized.
 *
 *  @param photoViewController        The `NYTPhotoViewController` instance that sent the delegate message.
 *  @param longPressGestureRecognizer The long press gesture recognizer that recognized the long press.
 */
- (void)photoViewController:(NYTPhotoViewController *)photoViewController didLongPressWithGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer;

@end

NS_ASSUME_NONNULL_END
