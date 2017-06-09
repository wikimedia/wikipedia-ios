@import UIKit;

@interface UIView (WMFDefaultNib)

/**
 * The name of the nib used to instantiate an instance of the receiver in <code>+[UIView wmf_viewFromClassNib]</code>.
 *
 * The default implementation returns the name of the receiver's class (similar to
 * <code>+[UIViewController nibName]</code>).
 */
+ (NSString *)wmf_nibName;

/**
 * Create a view by returning the top level object of the nib matching <code>+[UIView wmf_nibName]</code>.
 * @return An instance of the receiver.
 */
+ (instancetype)wmf_viewFromClassNib;

/**
 * Factory for the receiver's default nib.
 * @return The nib matching @c wmf_nibName in the main bundle.
 * @see wmf_nibName
 */
+ (UINib *)wmf_classNib;

@end
