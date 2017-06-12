#import <WMF/UIView+WMFDefaultNib.h>
#import <WMF/NSString+WMFExtras.h>

@implementation UIView (WMFDefaultNib)

+ (NSString *)wmf_nibName {
    /* Swift has "Namespaced" class names that prepend the module
     * For instance: "Wikipedia.MyCellClassName"
     * So we need to remove the "Wikipedia." for this to work
     */
    return [NSStringFromClass(self) wmf_substringAfterString:@"."];
}

+ (instancetype)wmf_viewFromClassNib {
    UIView *view = [[[self wmf_classNib] instantiateWithOwner:nil options:nil] firstObject];
    NSAssert(view, @"Instantiating %@ from default nib returned nil!", self);
    NSAssert([view isMemberOfClass:self], @"Expected %@ to be instance of class %@", view, self);
    return view;
}

+ (UINib *)wmf_classNib {
    return [UINib nibWithNibName:[self wmf_nibName] bundle:nil];
}

@end
