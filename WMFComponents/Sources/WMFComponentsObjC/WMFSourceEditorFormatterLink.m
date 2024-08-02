#import "WMFSourceEditorFormatterLink.h"
#import "WMFSourceEditorColors.h"

@interface WMFSourceEditorFormatterLink ()

@property (nonatomic, strong) NSDictionary *simpleLinkAttributes;
@property (nonatomic, strong) NSDictionary *linkWithNestedLinkAttributes;
@property (nonatomic, strong) NSRegularExpression *simpleLinkRegex;
@property (nonatomic, strong) NSRegularExpression *linkWithNestedLinkRegex;

@end

#pragma mark - Custom Attributed String Keys

NSString * const WMFSourceEditorCustomKeyColorBlue = @"WMFSourceEditorCustomKeyColorBlue";
NSString * const WMFSourceEditorCustomKeyLink = @"WMFSourceEditorCustomKeyLink";
NSString * const WMFSourceEditorCustomKeyLinkWithNestedLink = @"WMFSourceEditorCustomKeyLinkWithNestedLink";

@implementation WMFSourceEditorFormatterLink

#pragma mark - Public

- (instancetype)initWithColors:(nonnull WMFSourceEditorColors *)colors fonts:(nonnull WMFSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _simpleLinkAttributes = @{
            WMFSourceEditorCustomKeyLink: [NSNumber numberWithBool:YES],
            NSForegroundColorAttributeName: colors.blueForegroundColor,
            WMFSourceEditorCustomKeyColorBlue: [NSNumber numberWithBool:YES]
        };

        _simpleLinkRegex = [[NSRegularExpression alloc] initWithPattern:@"(\\[{2})([^\\[\\]\\n]*)(\\]{2})" options:0 error:nil];
        
        _linkWithNestedLinkAttributes = @{
            WMFSourceEditorCustomKeyLinkWithNestedLink: [NSNumber numberWithBool:YES],
            NSForegroundColorAttributeName: colors.blueForegroundColor,
            WMFSourceEditorCustomKeyColorBlue: [NSNumber numberWithBool:YES]
        };
        
        _linkWithNestedLinkRegex = [[NSRegularExpression alloc] initWithPattern:@"\\[{2}[^\\[\\]\\n]*\\[{2}" options:0 error:nil];
    }

    return self;
}

#pragma mark - Overrides

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    // Reset
    [attributedString removeAttribute:WMFSourceEditorCustomKeyColorBlue range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyLink range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyLinkWithNestedLink range:range];

    // This section finds and highlights simple links that do NOT contain nested links, e.g. [[Cat]] and [[Dog|puppy]].
    [self.simpleLinkRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange fullMatch = [result rangeAtIndex:0];
            NSRange openingRange = [result rangeAtIndex:1];
            NSRange contentRange = [result rangeAtIndex:2];
            NSRange closingRange = [result rangeAtIndex:3];

            if (openingRange.location != NSNotFound) {
                [attributedString addAttributes:self.simpleLinkAttributes range:openingRange];
            }
        
            if (contentRange.location != NSNotFound) {
                [attributedString addAttributes:self.simpleLinkAttributes range:contentRange];
            }

            if (closingRange.location != NSNotFound) {
                [attributedString addAttributes:self.simpleLinkAttributes range:closingRange];
            }
        }];
    
    // Note: This section finds and highlights links with nested links, which is common in image links. The regex matches any opening markup [[ followed by non-markup characters, then another opening markup [[. We then start to loop character-by-character, matching opening and closing tags to find and highlight links that contain other links.
    // Originally I tried to allow for infinite nested links via regex alone, but it performed too poorly.
    [self.linkWithNestedLinkRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                  usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        
        NSRange match = [result rangeAtIndex:0];
        
        if (match.location != NSNotFound) {
            
            NSArray *linkWithNestedLinkRanges = [self linkWithNestedLinkRangesInString:attributedString.string startingIndex:match.location];
            
            for (NSValue *value in linkWithNestedLinkRanges) {
                NSRange range = [value rangeValue];
                if (range.location != NSNotFound) {
                    [attributedString addAttributes:self.linkWithNestedLinkAttributes range:range];
                }
            }
        }
    }];
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    NSMutableDictionary *mutSimpleLinkAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.simpleLinkAttributes];
    [mutSimpleLinkAttributes setObject:colors.blueForegroundColor forKey:NSForegroundColorAttributeName];
    self.simpleLinkAttributes = [[NSDictionary alloc] initWithDictionary:mutSimpleLinkAttributes];
    
    NSMutableDictionary *mutLinkWithNestedLinkAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.linkWithNestedLinkAttributes];
    [mutLinkWithNestedLinkAttributes setObject:colors.blueForegroundColor forKey:NSForegroundColorAttributeName];
    self.linkWithNestedLinkAttributes = [[NSDictionary alloc] initWithDictionary:mutLinkWithNestedLinkAttributes];
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }

    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyColorBlue
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:@{NSForegroundColorAttributeName: colors.blueForegroundColor} range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSimpleLinkInRange:(NSRange)range {
    return [self attributedString:attributedString isKey:WMFSourceEditorCustomKeyLink inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isLinkWithNestedLinkInRange:(NSRange)range {
    
    return [self attributedString:attributedString isKey:WMFSourceEditorCustomKeyLinkWithNestedLink inRange:range];
}

#pragma mark - Private

- (NSArray *)linkWithNestedLinkRangesInString: (NSString *)string startingIndex: (NSUInteger)index {
    NSMutableArray *openingRanges = [[NSMutableArray alloc] init];
    NSMutableArray *completedLinkRanges = [[NSMutableArray alloc] init];
    NSMutableArray *completedLinkWithNestedLinkRanges = [[NSMutableArray alloc] init];

    // Loop through and evaluate characters in pairs, keeping track of opening and closing pairs
    BOOL lastCompletedLinkRangeWasNested = NO;
    for (NSUInteger i = index; i < string.length; i++) {
        
        unichar currentChar = [string characterAtIndex:i];
        
        if (currentChar == '\n') {
            break;
        }
        
        if (i + 1 >= string.length) {
            break;
        }
        
        NSString *currentCharString = [NSString stringWithFormat:@"%c", currentChar];
        unichar nextChar = [string characterAtIndex:i + 1];
        NSString *nextCharString = [NSString stringWithFormat:@"%c", nextChar];
        NSString *pair = [NSString stringWithFormat:@"%@%@", currentCharString, nextCharString];
        
        if ([pair isEqualToString:@"[["]) {
            [openingRanges addObject:[NSValue valueWithRange:NSMakeRange(i, 2)]];
        }
        
        if ([pair isEqualToString:@"]]"] && openingRanges.count == 0) {
            // invalid, closed markup before opening
            break;
        }
        
        if ([pair isEqualToString:@"]]"]) {
            
            NSValue *lastOpeningRange = openingRanges.lastObject;
            if (lastOpeningRange) {
                [openingRanges removeLastObject];
            }
            
            NSRange unionRange = NSUnionRange(lastOpeningRange.rangeValue, NSMakeRange(i, 2));
            NSValue *linkRange = [NSValue valueWithRange:unionRange];
            [completedLinkRanges addObject: linkRange];
            
            if (lastCompletedLinkRangeWasNested && openingRanges.count == 0) {
                [completedLinkWithNestedLinkRanges addObject:linkRange];
            }
            
            if (openingRanges.count > 0) {
                lastCompletedLinkRangeWasNested = YES;
            } else {
                lastCompletedLinkRangeWasNested = NO;
            }
        }
    }
    
    return [[NSArray alloc] initWithArray:completedLinkWithNestedLinkRanges];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isKey:(NSString *)key inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }
    
    __block BOOL isKey = NO;
    if (range.length == 0) {

           NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

           if (attrs[key] != nil) {
               isKey = YES;
           }
           
           // Edge case, check previous character if we are up against opening markup
            NSRange newRange = NSMakeRange(range.location - 1, 0);
           if (attrs[WMFSourceEditorCustomKeyLink] && [self canEvaluateAttributedString:attributedString againstRange:newRange]) {
               attrs = [attributedString attributesAtIndex:newRange.location effectiveRange:nil];
               if (attrs[key] == nil) {
                   isKey = NO;
               }
           }

       } else {
           __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
           [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
               if (attrs[key] != nil) {
                   if (unionRange.location == NSNotFound) {
                       unionRange = loopRange;
                   } else {
                       unionRange = NSUnionRange(unionRange, loopRange);
                   }
                   stop = YES;
               }
           }];

            if (NSEqualRanges(unionRange, range)) {
                isKey = YES;
            }
       }

       return isKey;
}

@end
