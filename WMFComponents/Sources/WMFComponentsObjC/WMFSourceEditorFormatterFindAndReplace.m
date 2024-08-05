#import "WMFSourceEditorFormatterFindAndReplace.h"
#import "WMFSourceEditorColors.h"
#import "WMFSourceEditorFonts.h"

@interface WMFSourceEditorFormatterFindAndReplace ()

@property (nonatomic, assign, readwrite) NSInteger selectedMatchIndex;

@property (nonatomic, copy, nullable) NSString *searchText;
@property (nonatomic, strong, nullable) NSRegularExpression *searchRegex;

@property (nonatomic, copy) NSAttributedString *fullAttributedString;
@property (nonatomic, strong) NSMutableArray<NSValue *> *matchesAgainstFullAttributedString;
@property (nonatomic, strong) NSMutableArray<NSValue *> *replacesAgainstFullAttributedString;

@property (nonatomic, copy) NSDictionary *matchAttributes;
@property (nonatomic, copy) NSDictionary *selectedMatchAttributes;
@property (nonatomic, copy) NSDictionary *replacedMatchAttributes;

@end

@implementation WMFSourceEditorFormatterFindAndReplace

#pragma mark - Custom Attributed String Keys

NSString * const WMFSourceEditorCustomKeyMatch = @"WMFSourceEditorCustomKeyMatch";
NSString * const WMFSourceEditorCustomKeySelectedMatch = @"WMFSourceEditorCustomKeySelectedMatch";
NSString * const WMFSourceEditorCustomKeyReplacedMatch = @"WMFSourceEditorCustomKeyReplacedMatch";

#pragma mark - Overrides

- (instancetype)initWithColors:(WMFSourceEditorColors *)colors fonts:(WMFSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _selectedMatchIndex = NSNotFound;

       _searchText = nil;
       _searchRegex = nil;

       _fullAttributedString = nil;
       _matchesAgainstFullAttributedString = [[NSMutableArray alloc] init];
        _replacesAgainstFullAttributedString = [[NSMutableArray alloc] init];

       _matchAttributes = @{
           NSForegroundColorAttributeName: colors.matchForegroundColor,
           NSBackgroundColorAttributeName: colors.matchBackgroundColor,
           WMFSourceEditorCustomKeyMatch: [NSNumber numberWithBool:YES]
       };

       _selectedMatchAttributes = @{
           NSForegroundColorAttributeName: colors.matchForegroundColor,
           NSBackgroundColorAttributeName: colors.selectedMatchBackgroundColor,
           WMFSourceEditorCustomKeySelectedMatch: [NSNumber numberWithBool:YES]
       };

       _replacedMatchAttributes = @{
           NSForegroundColorAttributeName: colors.matchForegroundColor,
           NSBackgroundColorAttributeName: colors.replacedMatchBackgroundColor,
           WMFSourceEditorCustomKeyReplacedMatch: [NSNumber numberWithBool:YES]
       };
    }
    
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    // This override is only needed for TextKit 2. The attributed string passed in here is regenerated fresh via the textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) delegate method, so we need to reapply attributes.

    // TextKit 2 only passes in the paragraph attributed string here, as opposed to the full document attributed string with TextKit 1. This conditional singles out TextKit 2.
    
    // Note: test this for a one line document, I think it breaks
    if (range.location == 0 && range.length < self.fullAttributedString.length) {
        
        NSRange paragraphRange = [self.fullAttributedString.string rangeOfString:attributedString.string];
        
        [self.matchesAgainstFullAttributedString enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange fullStringMatchRange = obj.rangeValue;
            
            // Find matches that only lie in paragraph range
            if (NSIntersectionRange(paragraphRange, fullStringMatchRange).length > 0) {

                NSDictionary *attributes = idx == self.selectedMatchIndex ? self.selectedMatchAttributes : self.matchAttributes;

                // Translate full string match back to paragraph match range
                NSRange paragraphMatchRange = NSMakeRange(fullStringMatchRange.location - paragraphRange.location, fullStringMatchRange.length);

                //Then reapply attributes to paragraph match range.
                if ([self canEvaluateAttributedString:attributedString againstRange:paragraphMatchRange]) {
                    [self resetKeysForAttributedString:attributedString range:paragraphMatchRange];
                    [attributedString addAttributes:attributes range:paragraphMatchRange];
                }
            }
        }];
        
        [self.replacesAgainstFullAttributedString enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange fullStringMatchRange = obj.rangeValue;
            
            // Find matches that only lie in paragraph range
            if (NSIntersectionRange(paragraphRange, fullStringMatchRange).length > 0) {

                // Translate full string match back to paragraph match range
                NSRange paragraphMatchRange = NSMakeRange(fullStringMatchRange.location - paragraphRange.location, fullStringMatchRange.length);

                //Then reapply attributes to paragraph match range.
                if ([self canEvaluateAttributedString:attributedString againstRange:paragraphMatchRange]) {
                    [self resetKeysForAttributedString:attributedString range:paragraphMatchRange];
                    [attributedString addAttributes:self.replacedMatchAttributes range:paragraphMatchRange];
                }
            }
        }];
    }
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
        return;
    }
    
    NSMutableDictionary *mutMatchAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.matchAttributes];
    [mutMatchAttributes setObject:colors.matchBackgroundColor forKey:NSBackgroundColorAttributeName];
    self.matchAttributes = [[NSDictionary alloc] initWithDictionary:mutMatchAttributes];

    NSMutableDictionary *mutSelectedMatchAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.selectedMatchAttributes];
    [mutSelectedMatchAttributes setObject:colors.selectedMatchBackgroundColor forKey:NSBackgroundColorAttributeName];
    self.selectedMatchAttributes = [[NSDictionary alloc] initWithDictionary:mutSelectedMatchAttributes];

    NSMutableDictionary *mutReplacedMatchAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.replacedMatchAttributes];
    [mutReplacedMatchAttributes setObject:colors.replacedMatchBackgroundColor forKey:NSBackgroundColorAttributeName];
    self.replacedMatchAttributes = [[NSDictionary alloc] initWithDictionary:mutReplacedMatchAttributes];

    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyMatch
                     inRange:range
                     options:nil
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.matchAttributes range:localRange];
            }
        }
    }];

    [attributedString enumerateAttribute:WMFSourceEditorCustomKeySelectedMatch
                     inRange:range
                     options:nil
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.selectedMatchAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyReplacedMatch
                     inRange:range
                     options:nil
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.replacedMatchAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

}

#pragma mark - Getters and Setters

- (NSInteger)matchCount {
    return self.matchesAgainstFullAttributedString.count;
}

- (NSRange)selectedMatchRange {
    if (self.matchesAgainstFullAttributedString.count > self.selectedMatchIndex) {
        NSValue *value = self.matchesAgainstFullAttributedString[self.selectedMatchIndex];
        return value.rangeValue;
    }

    return NSMakeRange(NSNotFound, 0);
}

- (NSRange)lastReplacedRange {
    if (self.replacesAgainstFullAttributedString.count > 0) {
        NSValue *value = self.replacesAgainstFullAttributedString[self.replacesAgainstFullAttributedString.count - 1];
        return value.rangeValue;
    }

    return NSMakeRange(NSNotFound, 0);
}

#pragma mark - Public

- (void)startMatchSessionWithFullAttributedString: (NSMutableAttributedString *)fullAttributedString searchText:(NSString *)searchText {
    
    self.searchText = searchText;
    self.searchRegex = [[NSRegularExpression alloc] initWithPattern:searchText options:NSRegularExpressionCaseInsensitive error:nil];
    
    [self calculateMatchesInFullAttributedString:fullAttributedString];
}

- (void)highlightNextMatchInFullAttributedString:(NSMutableAttributedString *)fullAttributedString afterRangeValue: (nullable NSValue *)afterRangeValue {
    
    if (self.matchesAgainstFullAttributedString.count == 0) {
        return;
    }
    
    NSInteger lastSelectedMatchIndex = self.selectedMatchIndex;
    
    if (self.selectedMatchIndex == NSNotFound && afterRangeValue && afterRangeValue.rangeValue.location != NSNotFound) {
        // find the first index AFTER the afterRangeValue param. This allows us to start selection highlights in the middle of the matches.
        int i = 0;
        for (NSValue *matchValue in self.matchesAgainstFullAttributedString) {
            NSRange matchRange = matchValue.rangeValue;
            
            if (matchRange.location >= afterRangeValue.rangeValue.location) {
                self.selectedMatchIndex = i;
                break;
            }
            
            i++;
        }
        
        if (self.selectedMatchIndex == NSNotFound) {
            self.selectedMatchIndex = 0;
        }
    } else if ((self.selectedMatchIndex == NSNotFound) || (self.selectedMatchIndex == self.matchesAgainstFullAttributedString.count - 1)) {
        self.selectedMatchIndex = 0;
    } else {
        self.selectedMatchIndex += 1;
    }

    [self updateMatchHighlightsInFullAttributedString:fullAttributedString lastSelectedMatchIndex:lastSelectedMatchIndex];
}

- (void)highlightPreviousMatchInFullAttributedString:(NSMutableAttributedString *)fullAttributedString {
    
    if (self.matchesAgainstFullAttributedString.count == 0) {
        return;
    }
    
    NSInteger lastSelectedMatchIndex = self.selectedMatchIndex;

    // Decrement index
    if ((self.selectedMatchIndex == NSNotFound) || (self.selectedMatchIndex == 0)) {
        self.selectedMatchIndex = self.matchesAgainstFullAttributedString.count - 1;
    } else {
        self.selectedMatchIndex -= 1;
    }

    [self updateMatchHighlightsInFullAttributedString:fullAttributedString lastSelectedMatchIndex:lastSelectedMatchIndex];
}

- (void)replaceSingleMatchInFullAttributedString:(NSMutableAttributedString *)fullAttributedString withReplaceText:(NSString *)replaceText textView: (UITextView *)textView {
    
    // add replace range to array
    NSRange newReplaceRange = NSMakeRange(self.selectedMatchRange.location, replaceText.length);
    NSValue *newReplaceRangeValue = [NSValue valueWithRange:newReplaceRange];
    [self.replacesAgainstFullAttributedString addObject:newReplaceRangeValue];

    // get currently selected match text range
    NSInteger selectedMatchIndex = self.selectedMatchIndex;
    NSRange selectedMatchRange = self.selectedMatchRange;
    UITextPosition *startPos = [textView positionFromPosition:textView.beginningOfDocument offset:selectedMatchRange.location];
    UITextPosition *endPos = [textView positionFromPosition:startPos offset:selectedMatchRange.length];
    UITextRange *selectedMatchTextRange = [textView textRangeFromPosition:startPos toPosition:endPos];

    // replace text in textview
    [textView replaceRange:selectedMatchTextRange withText:replaceText];
    
    // update replace range with new attributes
    if ([self canEvaluateAttributedString:fullAttributedString againstRange:newReplaceRange]) {
        [fullAttributedString beginEditing];
        [self resetKeysForAttributedString:fullAttributedString range:newReplaceRange];
        [fullAttributedString addAttributes:self.replacedMatchAttributes range:newReplaceRange];
        [fullAttributedString endEditing];
    }
    
    // copy new text view text to keep it in sync
    self.fullAttributedString = textView.attributedText;
    
    // reset matches
    [self.matchesAgainstFullAttributedString removeAllObjects];
    self.selectedMatchIndex = NSNotFound;
    
    // recalculate matches and select the first one
    [self calculateMatchesInFullAttributedString:fullAttributedString];
    [self highlightNextMatchInFullAttributedString:fullAttributedString afterRangeValue:newReplaceRangeValue];
}

- (void)replaceAllMatchesInFullAttributedString:(NSMutableAttributedString *)fullAttributedString withReplaceText:(NSString *)replaceText textView: (UITextView *)textView {
    
    NSInteger lengthDelta = replaceText.length - self.searchText.length;
    
    int i = 0;
    
    // copy so we aren't removing objects while enumerating an array
    NSArray *matchesCopy = [NSArray arrayWithArray:self.matchesAgainstFullAttributedString];
    for (NSValue *matchValue in matchesCopy) {
        NSRange matchRange = matchValue.rangeValue;
        
        // both match and replace ranges need to be adjusted for the text length differences for each iteration. Otherwise ranges are thrown off.
        NSRange offsetMatchRange = NSMakeRange(matchRange.location + (lengthDelta * i), self.searchText.length);
        NSRange newReplaceRange = NSMakeRange(matchRange.location + (lengthDelta * i), replaceText.length);
        
        // add replace range to array
        [self.replacesAgainstFullAttributedString addObject:[NSValue valueWithRange:newReplaceRange]];
        
        // get currently selected match text range
        UITextPosition *startPos = [textView positionFromPosition:textView.beginningOfDocument offset:offsetMatchRange.location];
        UITextPosition *endPos = [textView positionFromPosition:startPos offset:offsetMatchRange.length];
        UITextRange *matchTextRange = [textView textRangeFromPosition:startPos toPosition:endPos];
        
        // replace text in textview
        [textView replaceRange:matchTextRange withText:replaceText];
        
        // remove first match to keep in sync with remaining matches in text view.
        [self.matchesAgainstFullAttributedString removeObjectAtIndex:0];
        
        // update replace range with new attributes
        if ([self canEvaluateAttributedString:fullAttributedString againstRange:newReplaceRange]) {
            [fullAttributedString beginEditing];
            [self resetKeysForAttributedString:fullAttributedString range:newReplaceRange];
            [fullAttributedString addAttributes:self.replacedMatchAttributes range:newReplaceRange];
            [fullAttributedString endEditing];
        }
        
        // copy new text view text to keep it in sync
        self.fullAttributedString = textView.attributedText;
        
        i++;
    }
    
    // reset selected match index
    self.selectedMatchIndex = NSNotFound;
}


- (void)endMatchSessionWithFullAttributedString:(NSMutableAttributedString *)fullAttributedString {
    self.selectedMatchIndex = NSNotFound;

    self.searchText = nil;
    self.searchRegex = nil;

    self.fullAttributedString = nil;
    
    [self.matchesAgainstFullAttributedString removeAllObjects];
    [self.replacesAgainstFullAttributedString removeAllObjects];

    [fullAttributedString beginEditing];
    NSRange allRange = NSMakeRange(0, fullAttributedString.length);
    [self resetKeysForAttributedString:fullAttributedString range:allRange];
    [fullAttributedString endEditing];
}

#pragma mark - Private

- (void)calculateMatchesInFullAttributedString: (NSMutableAttributedString *)fullAttributedString {
    self.fullAttributedString = fullAttributedString;

    [fullAttributedString beginEditing];
    NSMutableArray *matchValues = [[NSMutableArray alloc] init];
    [self.searchRegex enumerateMatchesInString:fullAttributedString.string
                                        options:0
                                          range:NSMakeRange(0, fullAttributedString.length)
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange match = [result rangeAtIndex:0];

            if (match.location != NSNotFound) {
                [self resetKeysForAttributedString:fullAttributedString range:match];
                [fullAttributedString addAttributes:self.matchAttributes range:match];
                [matchValues addObject:[NSValue valueWithRange:match]];
            }
        }];
    [fullAttributedString endEditing];

    self.matchesAgainstFullAttributedString = matchValues;
}

- (void)updateMatchHighlightsInFullAttributedString: (NSMutableAttributedString *)fullAttributedString lastSelectedMatchIndex: (NSInteger)lastSelectedMatchIndex {
    
    [fullAttributedString beginEditing];

    // Pull next range and color as selected
    NSValue *nextMatchRangeValue = self.matchesAgainstFullAttributedString[self.selectedMatchIndex];
    NSRange nextMatchRange = nextMatchRangeValue.rangeValue;

    if ([self canEvaluateAttributedString:fullAttributedString againstRange:nextMatchRange]) {
        [self resetKeysForAttributedString:fullAttributedString range:nextMatchRange];
        [fullAttributedString addAttributes:self.selectedMatchAttributes range:nextMatchRange];
    }

    // Color last selected match as regular
    if (lastSelectedMatchIndex != NSNotFound && self.matchesAgainstFullAttributedString.count > lastSelectedMatchIndex) {
        NSValue *lastSelectedMatchRangeValue = self.matchesAgainstFullAttributedString[lastSelectedMatchIndex];
        NSRange lastSelectedMatchRange = lastSelectedMatchRangeValue.rangeValue;

        if ([self canEvaluateAttributedString:fullAttributedString againstRange:lastSelectedMatchRange]) {
            [self resetKeysForAttributedString:fullAttributedString range:lastSelectedMatchRange];
            [fullAttributedString addAttributes:self.matchAttributes range:lastSelectedMatchRange];
        }
    }

    [fullAttributedString endEditing];
}

- (void)resetKeysForAttributedString: (NSMutableAttributedString *)attributedString range: (NSRange) range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
        return;
    }
    
    [attributedString removeAttribute:NSForegroundColorAttributeName range:range];
    [attributedString removeAttribute:NSBackgroundColorAttributeName range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyMatch range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeySelectedMatch range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyReplacedMatch range:range];

}

@end
