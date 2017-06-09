@import UIKit;

@interface UIViewController (WMFStoryboardUtilities)

/**
 * Create an instance of the receiver using its default storyboard.
 * In general this should be used to DRY up the implementation of convienence methods.
 * Avoid using this to init a class externally as it will allow you to circumvent using designated initializers and convienence methods
 *
 *  @return A new instance of the receiver, loaded using the storyboard returned from @c wmf_classStoryboard.
 */
+ (instancetype)wmf_initialViewControllerFromClassStoryboard;

/**
 * @return The name of the storyboard used in @c wmf_initialViewControllerFromClassStoryboard. Defaults to @c NSStringFromClass(self).
 */
+ (NSString *)wmf_classStoryboardName;

/**
 *  @return Storyboard loaded from the receiver's bundle using the name returned by @c wmf_classStoryboardName.
 */
+ (UIStoryboard *)wmf_classStoryboard;

/**
 *  Create a new view controller from a storyboard by name.
 *  @see wmf_viewControllerWithIdentifier:fromStoryboard:
 */
+ (instancetype)wmf_viewControllerWithIdentifier:(NSString *)identifier
                             fromStoryboardNamed:(NSString *)storyboard;

/**
 *  Instantiate an instance of the receiver from a storyboard.
 *
 *  @warning This method will raise an assertion if the object obtained from the storyboard isn't an instance of the
 *           receiver. In release builds the object (or @c nil) will be returned.
 *
 *  @param identifier The identifier of the receiver set in the storyboard.
 *  @param storyboard The storyboard used to load the receiver's view.
 *
 *  @return A new instance of the receiver.
 */
+ (instancetype)wmf_viewControllerWithIdentifier:(NSString *)identifier
                                  fromStoryboard:(UIStoryboard *)storyboard;

@end
