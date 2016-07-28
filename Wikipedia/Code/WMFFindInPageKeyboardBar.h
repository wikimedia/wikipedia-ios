#import <UIKit/UIKit.h>

@class WMFFindInPageKeyboardBar;

@protocol WMFFindInPageKeyboardBarDelegate <NSObject>

- (void)keyboardBar:(WMFFindInPageKeyboardBar*)keyboardBar searchTermChanged:(NSString *)term;
- (void)keyboardBarCloseButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar;
- (void)keyboardBarClearButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar;
- (void)keyboardBarPreviousButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar;
- (void)keyboardBarNextButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar;

@end

@interface WMFFindInPageKeyboardBar : UIInputView

@property (weak, nonatomic) id<WMFFindInPageKeyboardBarDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic) NSUInteger numberOfMatches;
@property (nonatomic) NSInteger currentCursorIndex;

@end
