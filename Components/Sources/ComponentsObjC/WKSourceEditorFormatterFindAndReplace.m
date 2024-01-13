#import "WKSourceEditorFormatterFindAndReplace.h"
#import "WKSourceEditorColors.h"
#import "WKSourceEditorFonts.h"

@interface WKSourceEditorFormatterFindAndReplace ()

@property (nonatomic, assign, readwrite) NSInteger selectedMatchIndex;

@property (nonatomic, copy, nullable) NSString *searchText;
@property (nonatomic, strong, nullable) NSRegularExpression *searchRegex;

@property (nonatomic, copy) NSAttributedString *fullAttributedString;
@property (nonatomic, strong) NSMutableArray<NSValue *> *matchesAgainstFullAttributedString;

@property (nonatomic, copy) NSDictionary *matchAttributes;
@property (nonatomic, copy) NSDictionary *selectedMatchAttributes;
@property (nonatomic, copy) NSDictionary *replacedMatchAttributes;

@end

@implementation WKSourceEditorFormatterFindAndReplace

#pragma mark - Custom Attributed String Keys

NSString * const WKSourceEditorCustomKeyMatch = @"WKSourceEditorCustomKeyMatch";
NSString * const WKSourceEditorCustomKeySelectedMatch = @"WKSourceEditorCustomKeySelectedMatch";
NSString * const WKSourceEditorCustomKeyReplacedMatch = @"WKSourceEditorCustomKeyReplacedMatch";

#pragma mark - Overrides

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _selectedMatchIndex = NSNotFound;

       _searchText = nil;
       _searchRegex = nil;

       _fullAttributedString = nil;
       _matchesAgainstFullAttributedString = [[NSMutableArray alloc] init];

       _matchAttributes = @{
           NSForegroundColorAttributeName: colors.matchForegroundColor,
           NSBackgroundColorAttributeName: colors.matchBackgroundColor,
           WKSourceEditorCustomKeyMatch: [NSNumber numberWithBool:YES]
       };

       _selectedMatchAttributes = @{
           NSForegroundColorAttributeName: colors.matchForegroundColor,
           NSBackgroundColorAttributeName: colors.selectedMatchBackgroundColor,
           WKSourceEditorCustomKeySelectedMatch: [NSNumber numberWithBool:YES]
       };

       _replacedMatchAttributes = @{
           NSForegroundColorAttributeName: colors.matchForegroundColor,
           NSBackgroundColorAttributeName: colors.replacedMatchBackgroundColor,
           WKSourceEditorCustomKeyReplacedMatch: [NSNumber numberWithBool:YES]
       };
    }
    
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (self.matchCount == 0) {
        return;
    }

    // This override is only needed for TextKit 2. The attributed string passed in here is regenerated fresh via the textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) delegate method, so we need to reapply attributes.

    // TextKit 2 only passes in the paragraph attributed string here, as opposed to the full document attributed string with TextKit 1. This conditional singles out TextKit 2.
    
    // Note: test this for a one line document, I think it breaks
    if (range.location == 0 && range.length != self.fullAttributedString.length) {
        
        NSRange paragraphRange = [self.fullAttributedString.string rangeOfString:attributedString.string];
        
        [self.matchesAgainstFullAttributedString enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange fullStringMatchRange = obj.rangeValue;
            
            // Find matches that only lie in paragraph range
            if (NSIntersectionRange(paragraphRange, fullStringMatchRange).length > 0) {

                NSDictionary *attributes = idx == self.selectedMatchIndex ? self.selectedMatchAttributes : self.matchAttributes;

                // Translate full string match back to paragraph match range
                NSRange paragraphMatchRange = NSMakeRange(fullStringMatchRange.location - paragraphRange.location, fullStringMatchRange.length);

                //Then reapply attributes to paragraph match range.
                if (attributedString.length > paragraphMatchRange.location && attributedString.length > paragraphMatchRange.location + paragraphMatchRange.length) {
                    [self resetKeysForAttributedString:attributedString range:paragraphMatchRange];
                    [attributedString addAttributes:attributes range:paragraphMatchRange];
                }
            }
        }];
    }
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    NSMutableDictionary *mutMatchAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.matchAttributes];
    [mutMatchAttributes setObject:colors.matchBackgroundColor forKey:NSBackgroundColorAttributeName];
    self.matchAttributes = [[NSDictionary alloc] initWithDictionary:mutMatchAttributes];

    NSMutableDictionary *mutSelectedMatchAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.selectedMatchAttributes];
    [mutSelectedMatchAttributes setObject:colors.selectedMatchBackgroundColor forKey:NSBackgroundColorAttributeName];
    self.selectedMatchAttributes = [[NSDictionary alloc] initWithDictionary:mutSelectedMatchAttributes];

    NSMutableDictionary *mutReplacedMatchAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.replacedMatchAttributes];
    [mutReplacedMatchAttributes setObject:colors.replacedMatchBackgroundColor forKey:NSBackgroundColorAttributeName];
    self.replacedMatchAttributes = [[NSDictionary alloc] initWithDictionary:mutReplacedMatchAttributes];

    [attributedString enumerateAttribute:WKSourceEditorCustomKeyMatch
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

    [attributedString enumerateAttribute:WKSourceEditorCustomKeySelectedMatch
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
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyReplacedMatch
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

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

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

#pragma mark - Public

- (void)startMatchSessionWithFullAttributedString: (NSMutableAttributedString *)fullAttributedString searchText:(NSString *)searchText {
    
    self.searchText = searchText;
    self.searchRegex = [[NSRegularExpression alloc] initWithPattern:searchText options:NSRegularExpressionCaseInsensitive error:nil];
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

- (void)highlightNextMatchInFullAttributedString:(NSMutableAttributedString *)fullAttributedString {
    
    if (self.matchesAgainstFullAttributedString.count == 0) {
        return;
    }
    
    NSInteger lastSelectedMatchIndex = self.selectedMatchIndex;

    // Increment index
    if ((self.selectedMatchIndex == NSNotFound) || (self.selectedMatchIndex == self.matchesAgainstFullAttributedString.count - 1)) {
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


- (void)endMatchSessionWithFullAttributedString:(NSMutableAttributedString *)fullAttributedString {
    self.selectedMatchIndex = NSNotFound;

    self.searchText = nil;
    self.searchRegex = nil;

    self.fullAttributedString = nil;
    [self.matchesAgainstFullAttributedString removeAllObjects];

    [fullAttributedString beginEditing];
    NSRange allRange = NSMakeRange(0, fullAttributedString.length);
    [self resetKeysForAttributedString:fullAttributedString range:allRange];
    [fullAttributedString endEditing];
}

#pragma mark - Private

- (void)updateMatchHighlightsInFullAttributedString: (NSMutableAttributedString *)fullAttributedString lastSelectedMatchIndex: (NSInteger)lastSelectedMatchIndex {
    
    [fullAttributedString beginEditing];

    // Pull next range and color as selected
    NSValue *nextMatchRangeValue = self.matchesAgainstFullAttributedString[self.selectedMatchIndex];
    NSRange nextMatchRange = nextMatchRangeValue.rangeValue;

    if (fullAttributedString.length > nextMatchRange.location && fullAttributedString.length > nextMatchRange.location + nextMatchRange.length) {
        [self resetKeysForAttributedString:fullAttributedString range:nextMatchRange];
        [fullAttributedString addAttributes:self.selectedMatchAttributes range:nextMatchRange];
    }

    // Color last selected match as regular
    if (lastSelectedMatchIndex != NSNotFound && self.matchesAgainstFullAttributedString.count > lastSelectedMatchIndex) {
        NSValue *lastSelectedMatchRangeValue = self.matchesAgainstFullAttributedString[lastSelectedMatchIndex];
        NSRange lastSelectedMatchRange = lastSelectedMatchRangeValue.rangeValue;

        if (fullAttributedString.length > lastSelectedMatchRange.location && fullAttributedString.length > lastSelectedMatchRange.location + lastSelectedMatchRange.length) {
            [self resetKeysForAttributedString:fullAttributedString range:lastSelectedMatchRange];
            [fullAttributedString addAttributes:self.matchAttributes range:lastSelectedMatchRange];
        }
    }

    [fullAttributedString endEditing];
}

- (void)resetKeysForAttributedString: (NSMutableAttributedString *)attributedString range: (NSRange) range {
    [attributedString removeAttribute:NSForegroundColorAttributeName range:range];
    [attributedString removeAttribute:NSBackgroundColorAttributeName range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyMatch range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeySelectedMatch range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyReplacedMatch range:range];

}

@end
