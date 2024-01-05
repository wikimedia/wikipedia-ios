#import "WKSourceEditorFormatterLink.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterLink ()

@property (nonatomic, strong) NSDictionary *linkMarkupAttributes;
@property (nonatomic, strong) NSDictionary *linkContentAttributes;
@property (nonatomic, strong) NSDictionary *linkWithNestedLinkMarkupAndContentAttributes;
@property (nonatomic, strong) NSRegularExpression *linkRegex;
@property (nonatomic, strong) NSRegularExpression *linkWithNestedLinkRegex;

@end

#pragma mark - Custom Attributed String Keys

NSString * const WKSourceEditorCustomKeyColorBlue = @"WKSourceEditorCustomKeyColorBlue";
NSString * const WKSourceEditorCustomKeyMarkupLink = @"WKSourceEditorCustomKeyMarkupLink";
NSString * const WKSourceEditorCustomKeyContentLink = @"WKSourceEditorCustomKeyContentLink";
NSString * const WKSourceEditorCustomKeyMarkupAndContentLinkWithNestedLink = @"WKSourceEditorCustomKeyMarkupAndContentLinkWithNestedLink";

@implementation WKSourceEditorFormatterLink

#pragma mark - Public

- (instancetype)initWithColors:(nonnull WKSourceEditorColors *)colors fonts:(nonnull WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _linkMarkupAttributes = @{
            WKSourceEditorCustomKeyMarkupLink: [NSNumber numberWithBool:YES],
            NSForegroundColorAttributeName: colors.blueForegroundColor,
            WKSourceEditorCustomKeyColorBlue: [NSNumber numberWithBool:YES]
        };
        
        _linkContentAttributes = @{
            WKSourceEditorCustomKeyContentLink: [NSNumber numberWithBool:YES],
            NSForegroundColorAttributeName: colors.blueForegroundColor,
            WKSourceEditorCustomKeyColorBlue: [NSNumber numberWithBool:YES]
        };

        _linkRegex = [[NSRegularExpression alloc] initWithPattern:@"(\\[{2})([^\\[\\]\\n]*)(\\]{2})" options:0 error:nil];
        
        _linkWithNestedLinkMarkupAndContentAttributes = @{
            WKSourceEditorCustomKeyMarkupAndContentLinkWithNestedLink: [NSNumber numberWithBool:YES],
            NSForegroundColorAttributeName: colors.blueForegroundColor,
            WKSourceEditorCustomKeyColorBlue: [NSNumber numberWithBool:YES]
        };
        
        _linkWithNestedLinkRegex = [[NSRegularExpression alloc] initWithPattern:@"\\[{2}[^\\[\\]\\n]*\\[{2}" options:0 error:nil];
    }

    return self;
}

#pragma mark - Overrides

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // Reset
    [attributedString removeAttribute:WKSourceEditorCustomKeyColorBlue range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentLink range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyMarkupAndContentLinkWithNestedLink range:range];

    // This section finds and highlights simple links that do NOT contain nested links, e.g. [[Cat]] and [[Dog|puppy]].
    [self.linkRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange fullMatch = [result rangeAtIndex:0];
            NSRange openingRange = [result rangeAtIndex:1];
            NSRange contentRange = [result rangeAtIndex:2];
            NSRange closingRange = [result rangeAtIndex:3];

            if (openingRange.location != NSNotFound) {
                [attributedString addAttributes:self.linkMarkupAttributes range:openingRange];
            }
        
            if (contentRange.location != NSNotFound) {
                [attributedString addAttributes:self.linkContentAttributes range:contentRange];
            }

            if (closingRange.location != NSNotFound) {
                [attributedString addAttributes:self.linkMarkupAttributes range:closingRange];
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
                    [attributedString addAttributes:self.linkWithNestedLinkMarkupAndContentAttributes range:range];
                }
            }
        }
    }];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    NSMutableDictionary *mutLinkMarkupAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.linkMarkupAttributes];
    [mutLinkMarkupAttributes setObject:colors.blueForegroundColor forKey:NSForegroundColorAttributeName];
    self.linkMarkupAttributes = [[NSDictionary alloc] initWithDictionary:mutLinkMarkupAttributes];
    
    NSMutableDictionary *mutLinkContentAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.linkContentAttributes];
    [mutLinkContentAttributes setObject:colors.blueForegroundColor forKey:NSForegroundColorAttributeName];
    self.linkContentAttributes = [[NSDictionary alloc] initWithDictionary:mutLinkContentAttributes];
    
    NSMutableDictionary *mutLinkWithNestedLinkMarkupAndContentAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.linkWithNestedLinkMarkupAndContentAttributes];
    [mutLinkWithNestedLinkMarkupAndContentAttributes setObject:colors.blueForegroundColor forKey:NSForegroundColorAttributeName];
    self.linkWithNestedLinkMarkupAndContentAttributes = [[NSDictionary alloc] initWithDictionary:mutLinkWithNestedLinkMarkupAndContentAttributes];

    [attributedString enumerateAttribute:WKSourceEditorCustomKeyColorBlue
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

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed
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

@end
