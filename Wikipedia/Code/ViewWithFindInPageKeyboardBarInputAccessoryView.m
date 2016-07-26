#import "ViewWithFindInPageKeyboardBarInputAccessoryView.h"
#import "FindInPageKeyboardBar.h"
#import "UIView+WMFDefaultNib.h"

@interface ViewWithFindInPageKeyboardBarInputAccessoryView()

@property (nonatomic, readwrite, retain) UIView *inputAccessoryView;
    
@end

@implementation ViewWithFindInPageKeyboardBarInputAccessoryView

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputAccessoryView {
    if(!_inputAccessoryView) {
        FindInPageKeyboardBar* bar = [FindInPageKeyboardBar wmf_viewFromClassNib];
        bar.delegate = self.findInPageBarDelegate;
        _inputAccessoryView = bar;
    }
    return _inputAccessoryView;
}

@end
