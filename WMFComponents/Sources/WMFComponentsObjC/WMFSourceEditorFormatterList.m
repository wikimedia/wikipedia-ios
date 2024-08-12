#import "WMFSourceEditorFormatterList.h"
#import "WMFSourceEditorColors.h"

@interface WMFSourceEditorFormatterList ()

@property (nonatomic, strong) NSDictionary *orangeAttributes;

@property (nonatomic, strong) NSDictionary *bulletSingleContentAttributes;
@property (nonatomic, strong) NSDictionary *bulletMultipleContentAttributes;
@property (nonatomic, strong) NSDictionary *numberSingleContentAttributes;
@property (nonatomic, strong) NSDictionary *numberMultipleContentAttributes;

@property (nonatomic, strong) NSRegularExpression *bulletSingleRegex;
@property (nonatomic, strong) NSRegularExpression *bulletMultipleRegex;
@property (nonatomic, strong) NSRegularExpression *numberSingleRegex;
@property (nonatomic, strong) NSRegularExpression *numberMultipleRegex;

@end

@implementation WMFSourceEditorFormatterList

#pragma mark - Custom Attributed String Keys

NSString * const WMFSourceEditorCustomKeyContentBulletSingle = @"WMFSourceEditorCustomKeyContentBulletSingle";
NSString * const WMFSourceEditorCustomKeyContentBulletMultiple = @"WMFSourceEditorCustomKeyContentBulletMultiple";
NSString * const WMFSourceEditorCustomKeyContentNumberSingle = @"WMFSourceEditorCustomKeyContentNumberSingle";
NSString * const WMFSourceEditorCustomKeyContentNumberMultiple = @"WMFSourceEditorCustomKeyContentNumberMultiple";

#pragma mark - Overrides

- (instancetype)initWithColors:(WMFSourceEditorColors *)colors fonts:(WMFSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _orangeAttributes = @{
            NSForegroundColorAttributeName: colors.orangeForegroundColor,
            WMFSourceEditorCustomKeyColorOrange: [NSNumber numberWithBool:YES]
        };
        
        _bulletSingleContentAttributes = @{
            WMFSourceEditorCustomKeyContentBulletSingle: [NSNumber numberWithBool:YES]
        };
        
        _bulletMultipleContentAttributes = @{
            WMFSourceEditorCustomKeyContentBulletMultiple: [NSNumber numberWithBool:YES]
        };
        
        _numberSingleContentAttributes = @{
            WMFSourceEditorCustomKeyContentNumberSingle: [NSNumber numberWithBool:YES]
        };
        
        _numberMultipleContentAttributes = @{
            WMFSourceEditorCustomKeyContentNumberMultiple: [NSNumber numberWithBool:YES]
        };
        
        _bulletSingleRegex = [[NSRegularExpression alloc] initWithPattern:@"^(\\*{1})(.*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _bulletMultipleRegex = [[NSRegularExpression alloc] initWithPattern:@"^(\\*{2,})(.*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _numberSingleRegex = [[NSRegularExpression alloc] initWithPattern:@"^(#{1})(.*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _numberMultipleRegex = [[NSRegularExpression alloc] initWithPattern:@"^(#{2,})(.*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    }
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentBulletSingle range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentBulletMultiple range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentNumberSingle range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentNumberMultiple range:range];
   
    [self enumerateAndHighlightAttributedString:attributedString range:range singleRegex:self.bulletSingleRegex multipleRegex:self.bulletMultipleRegex singleContentAttributes:self.bulletSingleContentAttributes singleContentAttributes:self.bulletMultipleContentAttributes];
    [self enumerateAndHighlightAttributedString:attributedString range:range singleRegex:self.numberSingleRegex multipleRegex:self.numberMultipleRegex singleContentAttributes:self.numberSingleContentAttributes singleContentAttributes:self.numberMultipleContentAttributes];
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // First update orangeAttributes property so that addSyntaxHighlighting has the correct color the next time it is called
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.orangeAttributes];
    [mutAttributes setObject:colors.orangeForegroundColor forKey:NSForegroundColorAttributeName];
    self.orangeAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    // Then update entire attributed string orange color
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

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed for lists
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isBulletSingleInRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentBulletSingle inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isBulletMultipleInRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentBulletMultiple inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isNumberSingleInRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentNumberSingle inRange:range];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isNumberMultipleInRange:(NSRange)range {
    return [self attributedString:attributedString isContentKey:WMFSourceEditorCustomKeyContentNumberMultiple inRange:range];
}

#pragma mark - Private

- (void)enumerateAndHighlightAttributedString: (nonnull NSMutableAttributedString *)attributedString range:(NSRange)range singleRegex:(NSRegularExpression *)singleRegex multipleRegex:(NSRegularExpression *)multipleRegex singleContentAttributes:(NSDictionary<NSAttributedStringKey, id> *)singleContentAttributes singleContentAttributes:(NSDictionary<NSAttributedStringKey, id> *)multipleContentAttributes {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    NSMutableArray *multipleRanges = [[NSMutableArray alloc] init];
    
    [multipleRegex enumerateMatchesInString:attributedString.string
                                             options:0
                                               range:range
                                          usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        NSRange fullMatch = [result rangeAtIndex:0];
        NSRange orangeRange = [result rangeAtIndex:1];
        NSRange contentRange = [result rangeAtIndex:2];
        
        if (fullMatch.location != NSNotFound) {
            [multipleRanges addObject:[NSValue valueWithRange:fullMatch]];
        }
        
        if (orangeRange.location != NSNotFound) {
            [attributedString addAttributes:self.orangeAttributes range:orangeRange];
        }
        
        if (contentRange.location != NSNotFound) {
            [attributedString addAttributes:multipleContentAttributes range:contentRange];
        }
    }];
    
    [singleRegex enumerateMatchesInString:attributedString.string
                                             options:0
                                               range:range
                                          usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        NSRange fullMatch = [result rangeAtIndex:0];
        NSRange orangeRange = [result rangeAtIndex:1];
        NSRange contentRange = [result rangeAtIndex:2];
        
        BOOL alreadyMultiple = NO;
        for (NSValue *value in multipleRanges) {
            NSRange multipleRange = value.rangeValue;
            if (NSIntersectionRange(multipleRange, fullMatch).length != 0) {
                alreadyMultiple = YES;
            }
        }

        if (alreadyMultiple) {
            return;
        }

        
        if (orangeRange.location != NSNotFound) {
            [attributedString addAttributes:self.orangeAttributes range:orangeRange];
        }
        
        if (contentRange.location != NSNotFound) {
            [attributedString addAttributes:singleContentAttributes range:contentRange];
        }
    }];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isContentKey:(NSString *)contentKey inRange:(NSRange)range {
    __block BOOL isContentKey = NO;
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }

    if (range.length == 0) {

        NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

        if (attrs[contentKey] != nil) {
            isContentKey = YES;
        }
        
        // Edge case, check previous character in case we're at the end of the line and list isn't detected
        NSRange newRange = NSMakeRange(range.location - 1, 0);
        if ([self canEvaluateAttributedString:attributedString againstRange:newRange]) {
            NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:newRange.location effectiveRange:nil];
            
            if (attrs[contentKey] != nil) {
                isContentKey = YES;
            }
        }

    } else {
        [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
                if ((attrs[contentKey] != nil) &&
                    (loopRange.location == range.location && loopRange.length == range.length)) {
                    isContentKey = YES;
                    stop = YES;
                }
        }];
    }

    return isContentKey;
}

@end
