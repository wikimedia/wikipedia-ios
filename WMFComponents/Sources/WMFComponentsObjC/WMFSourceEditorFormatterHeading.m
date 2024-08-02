#import "WMFSourceEditorFormatterHeading.h"
#import "WMFSourceEditorColors.h"
#import "WMFSourceEditorFonts.h"

@interface WMFSourceEditorFormatterHeading ()
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

@implementation WMFSourceEditorFormatterHeading

#pragma mark - Custom Attributed String Keys

// Font custom keys span across entire match, i.e. "== Test ==". The entire match is a particular font. This helps us quickly seek and update fonts upon popover change.
NSString * const WMFSourceEditorCustomKeyFontHeading = @"WMFSourceEditorCustomKeyFontHeading";
NSString * const WMFSourceEditorCustomKeyFontSubheading1 = @"WMFSourceEditorCustomKeyFontSubheading1";
NSString * const WMFSourceEditorCustomKeyFontSubheading2 = @"WMFSourceEditorCustomKeyFontSubheading2";
NSString * const WMFSourceEditorCustomKeyFontSubheading3 = @"WMFSourceEditorCustomKeyFontSubheading3";
NSString * const WMFSourceEditorCustomKeyFontSubheading4 = @"WMFSourceEditorCustomKeyFontSubheading4";

// Content custom keys span across only the content, i.e. " Test ". This helps us detect for button selection states.
NSString * const WMFSourceEditorCustomKeyContentHeading = @"WMFSourceEditorCustomKeyContentHeading";
NSString * const WMFSourceEditorCustomKeyContentSubheading1 = @"WMFSourceEditorCustomKeyContentSubheading1";
NSString * const WMFSourceEditorCustomKeyContentSubheading2 = @"WMFSourceEditorCustomKeyContentSubheading2";
NSString * const WMFSourceEditorCustomKeyContentSubheading3 = @"WMFSourceEditorCustomKeyContentSubheading3";
NSString * const WMFSourceEditorCustomKeyContentSubheading4 = @"WMFSourceEditorCustomKeyContentSubheading4";

#pragma mark - Public

- (instancetype)initWithColors:(WMFSourceEditorColors *)colors fonts:(WMFSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _orangeAttributes = @{
            NSForegroundColorAttributeName: colors.orangeForegroundColor,
            WMFSourceEditorCustomKeyColorOrange: [NSNumber numberWithBool:YES]
        };
        
        _headingFontAttributes = @{
            NSFontAttributeName: fonts.headingFont,
            WMFSourceEditorCustomKeyFontHeading: [NSNumber numberWithBool:YES]
        };
        
        _subheading1FontAttributes = @{
            NSFontAttributeName: fonts.subheading1Font,
            WMFSourceEditorCustomKeyFontSubheading1: [NSNumber numberWithBool:YES]
        };
        
        _subheading2FontAttributes = @{
            NSFontAttributeName: fonts.subheading2Font,
            WMFSourceEditorCustomKeyFontSubheading2: [NSNumber numberWithBool:YES]
        };
        
        _subheading3FontAttributes = @{
            NSFontAttributeName: fonts.subheading3Font,
            WMFSourceEditorCustomKeyFontSubheading3: [NSNumber numberWithBool:YES]
        };
        
        _subheading4FontAttributes = @{
            NSFontAttributeName: fonts.subheading4Font,
            WMFSourceEditorCustomKeyFontSubheading4: [NSNumber numberWithBool:YES]
        };
        
        _headingContentAttributes = @{
            WMFSourceEditorCustomKeyContentHeading: [NSNumber numberWithBool:YES]
        };
        
        _subheading1ContentAttributes = @{
            WMFSourceEditorCustomKeyContentSubheading1: [NSNumber numberWithBool:YES]
        };
        
        _subheading2ContentAttributes = @{
            WMFSourceEditorCustomKeyContentSubheading2: [NSNumber numberWithBool:YES]
        };
        
        _subheading3ContentAttributes = @{
            WMFSourceEditorCustomKeyContentSubheading3: [NSNumber numberWithBool:YES]
        };
        
        _subheading4ContentAttributes = @{
            WMFSourceEditorCustomKeyContentSubheading4: [NSNumber numberWithBool:YES]
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
    [attributedString removeAttribute:WMFSourceEditorCustomKeyFontHeading range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyFontSubheading1 range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyFontSubheading2 range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyFontSubheading3 range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyFontSubheading4 range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentHeading range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentSubheading1 range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentSubheading2 range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentSubheading3 range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentSubheading4 range:range];
    
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.headingRegex fontAttributes:self.headingFontAttributes contentAttributes:self.headingContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading1Regex fontAttributes:self.subheading1FontAttributes contentAttributes:self.subheading1ContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading2Regex fontAttributes:self.subheading2FontAttributes contentAttributes:self.subheading2ContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading3Regex fontAttributes:self.subheading3FontAttributes contentAttributes:self.subheading3ContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading4Regex fontAttributes:self.subheading4FontAttributes contentAttributes:self.subheading4ContentAttributes];
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    [self updateColorAttributesWithColors:colors];
    [self enumerateAndUpdateColorsInAttributedString:attributedString range:range];
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    [self updateFontAttributesWithFonts:fonts];
    [self enumerateAndUpdateFontsInAttributedString:attributedString range:range];
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHeadingInRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentHeading inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading1InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentSubheading1 inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading2InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentSubheading2 inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading3InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentSubheading3 inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading4InRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentSubheading4 inRange:range];
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
            if (attrs[WMFSourceEditorCustomKeyColorOrange] && [self canEvaluateAttributedString:attributedString againstRange:newRange]) {
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

- (void)updateColorAttributesWithColors: (WMFSourceEditorColors *)colors {
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.orangeAttributes];
    [mutAttributes setObject:colors.orangeForegroundColor forKey:NSForegroundColorAttributeName];
    self.orangeAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
}

- (void)enumerateAndUpdateColorsInAttributedString: (NSMutableAttributedString *)attributedString range: (NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyColorOrange
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

- (void)updateFontAttributesWithFonts: (WMFSourceEditorFonts *)fonts {
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
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyFontHeading
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
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyFontSubheading1
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
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyFontSubheading2
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
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyFontSubheading3
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
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyFontSubheading4
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
