@import UIKit;
@import WMF.Swift;

@class WMFFindInPageKeyboardBar;

@protocol WMFFindInPageKeyboardBarDelegate <NSObject>

- (void)keyboardBar:(WMFFindInPageKeyboardBar *)keyboardBar searchTermChanged:(NSString *)term;
- (void)keyboardBarCloseButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar;
- (void)keyboardBarClearButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar;
- (void)keyboardBarPreviousButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar;
- (void)keyboardBarNextButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar;

@end

@interface WMFFindInPageKeyboardBar : UIInputView <WMFThemeable>

@property (weak, nonatomic) id<WMFFindInPageKeyboardBarDelegate> delegate;

- (BOOL)isVisible;
- (void)show;
- (void)hide;
- (void)reset;

- (void)updateForCurrentMatchIndex:(NSInteger)index matchesCount:(NSUInteger)count;

@end
