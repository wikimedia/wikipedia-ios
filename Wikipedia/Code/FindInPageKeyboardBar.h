#import <UIKit/UIKit.h>

@class FindInPageKeyboardBar;

@protocol FindInPageBarDelegate <NSObject>

- (void)findInPageTermChanged:(NSString *)text sender:(FindInPageKeyboardBar *)sender;
- (void)findInPageCloseButtonTapped;
- (void)findInPageClearButtonTapped;
- (void)findInPagePreviousButtonTapped;
- (void)findInPageNextButtonTapped;

@end

@interface FindInPageKeyboardBar : UIInputView

@property (weak, nonatomic) id<FindInPageBarDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic) NSUInteger numberOfMatches;
@property (nonatomic) NSInteger currentCursorIndex;

@end
