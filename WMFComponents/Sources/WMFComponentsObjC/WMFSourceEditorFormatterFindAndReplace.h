#import "WMFSourceEditorFormatter.h"
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterFindAndReplace : WMFSourceEditorFormatter

@property (nonatomic, assign, readonly) NSInteger selectedMatchIndex;
@property (nonatomic, assign, readonly) NSInteger matchCount;
@property (nonatomic, assign, readonly) NSRange selectedMatchRange;
@property (nonatomic, assign, readonly) NSRange lastReplacedRange;

- (void)startMatchSessionWithFullAttributedString: (NSMutableAttributedString *)fullAttributedString searchText:(NSString *)searchText;
- (void)highlightNextMatchInFullAttributedString:(NSMutableAttributedString *)fullAttributedString afterRangeValue:(nullable NSValue *)afterRangeValue;
- (void)highlightPreviousMatchInFullAttributedString: (NSMutableAttributedString *)fullAttributedString;
- (void)replaceSingleMatchInFullAttributedString:(NSMutableAttributedString *)fullAttributedString withReplaceText:(NSString *)replaceText textView: (UITextView *)textView;
- (void)replaceAllMatchesInFullAttributedString:(NSMutableAttributedString *)fullAttributedString withReplaceText:(NSString *)replaceText textView: (UITextView *)textView;
- (void)endMatchSessionWithFullAttributedString: (NSMutableAttributedString *)fullAttributedString;

@end

NS_ASSUME_NONNULL_END
