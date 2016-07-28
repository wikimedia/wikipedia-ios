#import <UIKit/UIKit.h>

@class WMFFindInPageKeyboardBar;

@protocol WMFFindInPageBarDelegate <NSObject>

- (void)findInPageSearchTermChanged:(NSString *)term;
- (void)findInPageCloseButtonTapped;
- (void)findInPageClearButtonTapped;
- (void)findInPagePreviousButtonTapped;
- (void)findInPageNextButtonTapped;

@end

@interface WMFFindInPageKeyboardBar : UIInputView

@property (weak, nonatomic) id<WMFFindInPageBarDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic) NSUInteger numberOfMatches;
@property (nonatomic) NSInteger currentCursorIndex;

@end
