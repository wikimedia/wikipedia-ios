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

@property (nonatomic, strong) NSRegularExpression *headingRegex;
@property (nonatomic, strong) NSRegularExpression *subheading1Regex;
@property (nonatomic, strong) NSRegularExpression *subheading2Regex;
@property (nonatomic, strong) NSRegularExpression *subheading3Regex;
@property (nonatomic, strong) NSRegularExpression *subheading4Regex;
@end

@implementation WKSourceEditorFormatterHeading

#pragma mark - Custom Attributed String Keys

NSString * const WKSourceEditorCustomKeyFontHeading = @"WKSourceEditorCustomKeyFontHeading";
NSString * const WKSourceEditorCustomKeyFontSubheading1 = @"WKSourceEditorCustomKeyFontSubheading1";
NSString * const WKSourceEditorCustomKeyFontSubheading2 = @"WKSourceEditorCustomKeyFontSubheading2";
NSString * const WKSourceEditorCustomKeyFontSubheading3 = @"WKSourceEditorCustomKeyFontSubheading3";
NSString * const WKSourceEditorCustomKeyFontSubheading4 = @"WKSourceEditorCustomKeyFontSubheading4";

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
    
    // Reset
    [attributedString removeAttribute:WKSourceEditorCustomKeyColorOrange range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontHeading range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading1 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading2 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading3 range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontSubheading4 range:range];
    
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.headingRegex attributes:self.headingFontAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading1Regex attributes:self.subheading1FontAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading2Regex attributes:self.subheading2FontAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading3Regex attributes:self.subheading3FontAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range regex:self.subheading4Regex attributes:self.subheading4FontAttributes];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    [self updateColorAttributesWithColors:colors];
    [self enumerateAndUpdateColorsInAttributedString:attributedString range:range];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    [self updateFontAttributesWithFonts:fonts];
    [self enumerateAndUpdateFontsInAttributedString:attributedString range:range];
}

#pragma mark - Private

- (void)enumerateAndHighlightAttributedString: (nonnull NSMutableAttributedString *)attributedString range:(NSRange)range regex:(NSRegularExpression *)regex attributes:(NSDictionary<NSAttributedStringKey, id> *)fontAttributes {
    
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
