#import "WKSourceEditorFormatterTemplate.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterTemplate ()

@property (nonatomic, strong) NSDictionary *templateAttributes;
@property (nonatomic, strong) NSRegularExpression *sameLineTemplateRegex;

@end

@implementation WKSourceEditorFormatterTemplate

#pragma mark - Custom Attributed String Keys

NSString * const WKSourceEditorCustomKeyColorPurple = @"WKSourceEditorKeyColorPurple";
NSString * const WKSourceEditorCustomKeyTemplate = @"WKSourceEditorCustomKeyTemplate";

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        
        _templateAttributes = @{
            NSForegroundColorAttributeName: colors.purpleForegroundColor,
            WKSourceEditorCustomKeyTemplate: [NSNumber numberWithBool:YES]
        };
        
        _sameLineTemplateRegex = [[NSRegularExpression alloc] initWithPattern:@"\\{{2}[^\\{\\}\\n]*\\}{2}" options:0 error:nil];
    }
    return self;
}

#pragma mark - Overrides

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // Reset
    [attributedString removeAttribute:WKSourceEditorCustomKeyTemplate range:range];
    
    [self.sameLineTemplateRegex enumerateMatchesInString:attributedString.string
                                                 options:0
                                                   range:range
                                              usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                  NSRange matchRange = [result rangeAtIndex:0];

                                                  if (matchRange.location != NSNotFound) {
                                                      [attributedString addAttributes:self.templateAttributes range:matchRange];
                                                  }
                                              }];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.templateAttributes];
    [mutAttributes setObject:colors.purpleForegroundColor forKey:NSForegroundColorAttributeName];
    self.templateAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyTemplate
                     inRange:range
                     options:nil
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.templateAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed for templates
}

@end
