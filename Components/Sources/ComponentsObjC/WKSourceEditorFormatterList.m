#import "WKSourceEditorFormatterList.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterList ()

@property (nonatomic, strong) NSDictionary *orangeAttributes;

@property (nonatomic, strong) NSRegularExpression *bulletRegex;
@property (nonatomic, strong) NSRegularExpression *numberRegex;

@end

@implementation WKSourceEditorFormatterList

#pragma mark - Overrides

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _orangeAttributes = @{
            NSForegroundColorAttributeName: colors.orangeForegroundColor,
            WKSourceEditorCustomKeyColorOrange: [NSNumber numberWithBool:YES]
        };
        
        _bulletRegex = [[NSRegularExpression alloc] initWithPattern:@"^(\\*+)(.*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _numberRegex = [[NSRegularExpression alloc] initWithPattern:@"^(#+)(.*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    }
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    [self.bulletRegex enumerateMatchesInString:attributedString.string
                                       options:0
                                         range:range
                                    usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                        NSRange fullMatch = [result rangeAtIndex:0];
                                        NSRange bulletRange = [result rangeAtIndex:1];
        
                                        if (bulletRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:bulletRange];
                                        }
                                    }];
    
    [self.numberRegex enumerateMatchesInString:attributedString.string
                                       options:0
                                         range:range
                                    usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                        NSRange fullMatch = [result rangeAtIndex:0];
                                        NSRange numberRange = [result rangeAtIndex:1];
        
                                        if (numberRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:numberRange];
                                        }
                                    }];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // First update orangeAttributes property so that addSyntaxHighlighting has the correct color the next time it is called
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.orangeAttributes];
    [mutAttributes setObject:colors.orangeForegroundColor forKey:NSForegroundColorAttributeName];
    self.orangeAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
    
    // Then update entire attributed string orange color
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

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed for lists
}

@end
