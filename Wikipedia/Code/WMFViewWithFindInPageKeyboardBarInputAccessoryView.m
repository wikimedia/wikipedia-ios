#import "WMFViewWithFindInPageKeyboardBarInputAccessoryView.h"
#import "WMFFindInPageKeyboardBar.h"
#import "UIView+WMFDefaultNib.h"

@interface WMFViewWithFindInPageKeyboardBarInputAccessoryView()

@property (nonatomic, readwrite, retain) UIView *inputAccessoryView;
    
@end

@implementation WMFViewWithFindInPageKeyboardBarInputAccessoryView

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputAccessoryView {
    if(!_inputAccessoryView) {
        WMFFindInPageKeyboardBar* bar = [WMFFindInPageKeyboardBar wmf_viewFromClassNib];
        bar.delegate = self.findInPageBarDelegate;
        _inputAccessoryView = bar;
    }
    return _inputAccessoryView;
}

@end
