#import "WKSourceEditorFormatterStrikethrough.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterStrikethrough ()

@property (nonatomic, strong) NSDictionary *strikethroughAttributes;
@property (nonatomic, strong) NSRegularExpression *strikethroughRegex;

@end

@implementation WKSourceEditorFormatterStrikethrough

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _strikethroughAttributes = @{
            NSForegroundColorAttributeName: colors.greenForegroundColor,
            WKSourceEditorCustomKeyColorGreen: [NSNumber numberWithBool:YES]
        };
        
        _strikethroughRegex = [[NSRegularExpression alloc] initWithPattern:@"(<s>)(\\s*.*?)(<\\/s>)" options:0 error:nil];
    }
    
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    [self.strikethroughRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange fullMatch = [result rangeAtIndex:0];
            NSRange openingRange = [result rangeAtIndex:1];
            NSRange contentRange = [result rangeAtIndex:2];
            NSRange closingRange = [result rangeAtIndex:3];

            if (openingRange.location != NSNotFound) {
                [attributedString addAttributes:self.strikethroughAttributes range:openingRange];
            }

            if (closingRange.location != NSNotFound) {
                [attributedString addAttributes:self.strikethroughAttributes range:closingRange];
            }
        }];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.strikethroughAttributes];
    [mutAttributes setObject:colors.greenForegroundColor forKey:NSForegroundColorAttributeName];
    self.strikethroughAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];

    [attributedString enumerateAttribute:WKSourceEditorCustomKeyColorGreen
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.strikethroughAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed for references
}

@end
