#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterFindAndReplace : WKSourceEditorFormatter

@property (nonatomic, assign, readonly) NSInteger selectedMatchIndex;
@property (nonatomic, assign, readonly) NSInteger matchCount;
@property (nonatomic, assign, readonly) NSRange selectedMatchRange;
@property (nonatomic, assign, readonly) NSRange lastReplacedRange;

- (void)startMatchSessionWithFullAttributedString: (NSMutableAttributedString *)fullAttributedString searchText:(NSString *)searchText;
- (void)highlightNextMatchInFullAttributedString:(NSMutableAttributedString *)fullAttributedString afterRangeValue:(nullable NSValue *)afterRangeValue;
- (void)highlightPreviousMatchInFullAttributedString: (NSMutableAttributedString *)fullAttributedString;
- (void)endMatchSessionWithFullAttributedString: (NSMutableAttributedString *)fullAttributedString;

@end

NS_ASSUME_NONNULL_END
