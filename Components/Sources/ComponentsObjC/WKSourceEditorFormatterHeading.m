#import "WKSourceEditorFormatterHeading.h"
#import "WKSourceEditorColors.h"
#import "WKSourceEditorFonts.h"

@interface WKSourceEditorFormatterHeading ()
@property (nonatomic, strong) NSDictionary *headingFontAttributes;
@property (nonatomic, strong) NSDictionary *subheading1FontAttributes;
@property (nonatomic, strong) NSDictionary *subheading2FontAttributes;
@property (nonatomic, strong) NSDictionary *subheading3FontAttributes;
@property (nonatomic, strong) NSDictionary *subheading4FontAttributes;
@property (nonatomic, strong) NSDictionary *orangeAttributes;

@property (nonatomic, strong) NSDictionary *headingContentAttributes;
@property (nonatomic, strong) NSDictionary *subheading1ContentAttributes;
@property (nonatomic, strong) NSDictionary *subheading2ContentAttributes;
@property (nonatomic, strong) NSDictionary *subheading3ContentAttributes;
@property (nonatomic, strong) NSDictionary *subheading4ContentAttributes;

@property (nonatomic, strong) NSRegularExpression *headingRegex;
@property (nonatomic, strong) NSRegularExpression *subheading1Regex;
@property (nonatomic, strong) NSRegularExpression *subheading2Regex;
@property (nonatomic, strong) NSRegularExpression *subheading3Regex;
@property (nonatomic, strong) NSRegularExpression *subheading4Regex;
@end

@implementation WKSourceEditorFormatterHeading

#pragma mark - Custom Attributed String Keys

// Font custom keys span across entire match, i.e. "== Test ==". The entire match is a particular font. This helps us quickly seek and update fonts upon popover change.
NSString * const WKSourceEditorCustomKeyFontHeading = @"WKSourceEditorCustomKeyFontHeading";
NSString * const WKSourceEditorCustomKeyFontSubheading1 = @"WKSourceEditorCustomKeyFontSubheading1";
NSString * const WKSourceEditorCustomKeyFontSubheading2 = @"WKSourceEditorCustomKeyFontSubheading2";
NSString * const WKSourceEditorCustomKeyFontSubheading3 = @"WKSourceEditorCustomKeyFontSubheading3";
NSString * const WKSourceEditorCustomKeyFontSubheading4 = @"WKSourceEditorCustomKeyFontSubheading4";

// Content custom keys span across only the content, i.e. " Test ". This helps us detect for button selection states.
NSString * const WKSourceEditorCustomKeyContentHeading = @"WKSourceEditorCustomKeyContentHeading";
NSString * const WKSourceEditorCustomKeyContentSubheading1 = @"WKSourceEditorCustomKeyContentSubheading1";
NSString * const WKSourceEditorCustomKeyContentSubheading2 = @"WKSourceEditorCustomKeyContentSubheading2";
NSString * const WKSourceEditorCustomKeyContentSubheading3 = @"WKSourceEditorCustomKeyContentSubheading3";
NSString * const WKSourceEditorCustomKeyContentSubheading4 = @"WKSourceEditorCustomKeyContentSubheading4";

#pragma mark - Public

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _orangeAttributes = @{
            NSForegroundColorAttributeName: colors.orangeForegroundColor,
            WKSourceEditorCustomKeyColorOrange: [NSNumber numberWithBool:YES]
        };
        
        _headingFontAttributes = @{
            NSFontAttributeName: fonts.headingFont,
            WKSourceEditorCustomKeyFontHeading: [NSNumber numberWithBool:YES]
        };
        
        _subheading1FontAttributes = @{
            NSFontAttributeName: fonts.subheading1Font,
            WKSourceEditorCustomKeyFontSubheading1: [NSNumber numberWithBool:YES]
        };
        
        _subheading2FontAttributes = @{
            NSFontAttributeName: fonts.subheading2Font,
            WKSourceEditorCustomKeyFontSubheading2: [NSNumber numberWithBool:YES]
        };
        
        _subheading3FontAttributes = @{
            NSFontAttributeName: fonts.subheading3Font,
            WKSourceEditorCustomKeyFontSubheading3: [NSNumber numberWithBool:YES]
        };
        
        _subheading4FontAttributes = @{
            NSFontAttributeName: fonts.subheading4Font,
            WKSourceEditorCustomKeyFontSubheading4: [NSNumber numberWithBool:YES]
        };
        
        _headingContentAttributes = @{
            WKSourceEditorCustomKeyContentHeading: [NSNumber numberWithBool:YES]
        };
        
        _subheading1ContentAttributes = @{
            WKSourceEditorCustomKeyContentSubheading1: [NSNumber numberWithBool:YES]
        };
        
        _subheading2ContentAttributes = @{
            WKSourceEditorCustomKeyContentSubheading2: [NSNumber numberWithBool:YES]
        };
        
        _subheading3ContentAttributes = @{
            WKSourceEditorCustomKeyContentSubheading3: [NSNumber numberWithBool:YES]
        };
        
        _subheading4ContentAttributes = @{
            WKSourceEditorCustomKeyContentSubheading4: [NSNumber numberWithBool:YES]
        };
        
        _headingRegex = [[NSRegularExpression alloc] initWithPattern:@"^(={2})([^=]*)(={2})(?!=)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _subheading1Regex = [[NSRegularExpression alloc] initWithPattern:@"^(={3})([^=]*)(={3})(?!=)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _subheading2Regex = [[NSRegularExpression alloc] initWithPattern:@"^(={4})([^=]*)(={4})(?!=)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _subheading3Regex = [[NSRegularExpression alloc] initWithPattern:@"^(={5})([^=]*)(={5})(?!=)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _subheading4Regex = [[NSRegularExpression alloc] initWithPattern:@"^(={6})([^=]*)(={6})(?!=)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    }
    return self;
}

#pragma mark - Overrides

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    // Reset
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontHeading range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading1 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading2 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading3 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading4 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentHeading range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentSubheading1 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentSubheading2 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentSubheading3 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentSubheading4 range:range];
    
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.headingRegex fontAttributes:self.headingFontAttributes contentAttributes:self.headingContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading1Regex fontAttributes:self.subheading1FontAttributes contentAttributes:self.subheading1ContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading2Regex fontAttributes:self.subheading2FontAttributes contentAttributes:self.subheading2ContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading3Regex fontAttributes:self.subheading3FontAttributes contentAttributes:self.subheading3ContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading4Regex fontAttributes:self.subheading4FontAttributes contentAttributes:self.subheading4ContentAttributes];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    [self updateColorAttributesWithColors:colors];
    [self enumerateAndUpdateColorsInAttributedString:attributedString range:range];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    [self updateFontAttributesWithFonts:fonts];
    [self enumerateAndUpdateFontsInAttributedString:attributedString range:range];
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHeadingInRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WKSourceEditorCustomKeyContentHeading inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading1InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WKSourceEditorCustomKeyContentSubheading1 inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading2InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WKSourceEditorCustomKeyContentSubheading2 inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading3InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WKSourceEditorCustomKeyContentSubheading3 inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading4InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WKSourceEditorCustomKeyContentSubheading4 inRange:range];
}

#pragma mark - Private

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isContentKey:(NSString *)contentKey inRange:(NSRange)range {
    __block BOOL isContentKey = NO;
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }
    
    if (range.length == 0) {
        
        NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];
        
        if (attrs[contentKey] != nil) {
            isContentKey = YES;
        } else {
            // Edge case, check previous character if we are up against closing string
            NSRange newRange = NSMakeRange(range.location - 1, 0);
            if (attrs[WKSourceEditorCustomKeyColorOrange] && [self canEvaluateAttributedString:attributedString againstRange:newRange]) {
                attrs = [attributedString attributesAtIndex:newRange.location effectiveRange:nil];
                if (attrs[contentKey] != nil) {
                    isContentKey = YES;
                }
            }
        }
        
    } else {
        __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
        [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
                if (attrs[contentKey] != nil) {
                    if (unionRange.location == NSNotFound) {
                        unionRange = loopRange;
                    } else {
                        unionRange = NSUnionRange(unionRange, loopRange);
                    }
                    stop = YES;
                }
        }];
        
        if (NSEqualRanges(unionRange, range)) {
            isContentKey = YES;
        }
    }
    
    return isContentKey;
}

- (void)enumerateAndHighlightAttributedString: (nonnull NSMutableAttributedString *)attributedString range:(NSRange)range regex:(NSRegularExpression *)regex fontAttributes:(NSDictionary<NSAttributedStringKey, id> *)fontAttributes contentAttributes:(NSDictionary<NSAttributedStringKey, id> *)contentAttributes {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    [regex enumerateMatchesInString:attributedString.string
                            options:0
                              range:range
                         usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        NSRange fullMatch = [result rangeAtIndex:0];
        NSRange openingRange = [result rangeAtIndex:1];
        NSRange textRange = [result rangeAtIndex:2];
        NSRange closingRange = [result rangeAtIndex:3];
        
        if (fullMatch.location != NSNotFound) {
            [attributedString addAttributes:fontAttributes range:fullMatch];
        }
        
        if (openingRange.location != NSNotFound) {
            [attributedString addAttributes:self.orangeAttributes range:openingRange];
        }
        
        if (textRange.location != NSNotFound) {
            [attributedString addAttributes:contentAttributes range:textRange];
        }
        
        if (closingRange.location != NSNotFound) {
            [attributedString addAttributes:self.orangeAttributes range:closingRange];
        }
    }];
}

- (void)updateColorAttributesWithColors: (WKSourceEditorColors *)colors {
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.orangeAttributes];
    [mutAttributes setObject:colors.orangeForegroundColor forKey:NSForegroundColorAttributeName];
    self.orangeAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
}

- (void)enumerateAndUpdateColorsInAttributedString: (NSMutableAttributedString *)attributedString range: (NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyColorOrange
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.orangeAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFontAttributesWithFonts: (WKSourceEditorFonts *)fonts {
    NSMutableDictionary *mutHeadingAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.headingFontAttributes];
    [mutHeadingAttributes setObject:fonts.headingFont forKey:NSFontAttributeName];
    self.headingFontAttributes = [[NSDictionary alloc] initWithDictionary:mutHeadingAttributes];
    
    NSMutableDictionary *mutSubheading1Attributes = [[NSMutableDictionary alloc] initWithDictionary:self.subheading1FontAttributes];
    [mutSubheading1Attributes setObject:fonts.subheading1Font forKey:NSFontAttributeName];
    self.subheading1FontAttributes = [[NSDictionary alloc] initWithDictionary:mutSubheading1Attributes];
    
    NSMutableDictionary *mutSubheading2Attributes = [[NSMutableDictionary alloc] initWithDictionary:self.subheading2FontAttributes];
    [mutSubheading2Attributes setObject:fonts.subheading2Font forKey:NSFontAttributeName];
    self.subheading2FontAttributes = [[NSDictionary alloc] initWithDictionary:mutSubheading2Attributes];
    
    NSMutableDictionary *mutSubheading3Attributes = [[NSMutableDictionary alloc] initWithDictionary:self.subheading3FontAttributes];
    [mutSubheading3Attributes setObject:fonts.subheading3Font forKey:NSFontAttributeName];
    self.subheading3FontAttributes = [[NSDictionary alloc] initWithDictionary:mutSubheading3Attributes];
    
    NSMutableDictionary *mutSubheading4Attributes = [[NSMutableDictionary alloc] initWithDictionary:self.subheading4FontAttributes];
    [mutSubheading4Attributes setObject:fonts.subheading4Font forKey:NSFontAttributeName];
    self.subheading4FontAttributes = [[NSDictionary alloc] initWithDictionary:mutSubheading4Attributes];
}

- (void)enumerateAndUpdateFontsInAttributedString: (NSMutableAttributedString *)attributedString range: (NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontHeading
                                 inRange:range
                                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.headingFontAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontSubheading1
                                 inRange:range
                                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.subheading1FontAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontSubheading2
                                 inRange:range
                                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.subheading2FontAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontSubheading3
                                 inRange:range
                                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.subheading3FontAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontSubheading4
                                 inRange:range
                                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.subheading4FontAttributes range:localRange];
            }
        }
    }];
}

@end
