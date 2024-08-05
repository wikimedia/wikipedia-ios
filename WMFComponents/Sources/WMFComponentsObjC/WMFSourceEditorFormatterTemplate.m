#import "WMFSourceEditorFormatterTemplate.h"
#import "WMFSourceEditorColors.h"

@interface WMFSourceEditorFormatterTemplate ()

@property (nonatomic, strong) NSDictionary *horizontalTemplateAttributes;
@property (nonatomic, strong) NSDictionary *verticalTemplateAttributes;
@property (nonatomic, strong) NSRegularExpression *horizontalTemplateRegex;
@property (nonatomic, strong) NSRegularExpression *verticalStartTemplateRegex;
@property (nonatomic, strong) NSRegularExpression *verticalParameterTemplateRegex;
@property (nonatomic, strong) NSRegularExpression *verticalEndTemplateRegex;

@end

@implementation WMFSourceEditorFormatterTemplate

#pragma mark - Custom Attributed String Keys

NSString * const WMFSourceEditorCustomKeyHorizontalTemplate = @"WMFSourceEditorCustomKeyHorizontalTemplate";
NSString * const WMFSourceEditorCustomKeyVerticalTemplate = @"WMFSourceEditorCustomKeyVerticalTemplate";

- (instancetype)initWithColors:(WMFSourceEditorColors *)colors fonts:(WMFSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        
        _horizontalTemplateAttributes = @{
            NSForegroundColorAttributeName: colors.purpleForegroundColor,
            WMFSourceEditorCustomKeyHorizontalTemplate: [NSNumber numberWithBool:YES],
        };
        
        _verticalTemplateAttributes = @{
            NSForegroundColorAttributeName: colors.purpleForegroundColor,
            WMFSourceEditorCustomKeyVerticalTemplate: [NSNumber numberWithBool:YES]
        };
        
        _horizontalTemplateRegex = [[NSRegularExpression alloc] initWithPattern:@"\\{{2}[^\\{\\}\\n]*(?:\\{{2}[^\\{\\}\\n]*\\}{2})*[^\\{\\}\\n]*\\}{2}" options:0 error:nil];
        _verticalStartTemplateRegex = [[NSRegularExpression alloc] initWithPattern:@"^(?:.*)(\\{{2}[^\\{\\}\\n]*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _verticalParameterTemplateRegex = [[NSRegularExpression alloc] initWithPattern:@"^\\s*\\|.*$" options:NSRegularExpressionAnchorsMatchLines error:nil];
        _verticalEndTemplateRegex = [[NSRegularExpression alloc] initWithPattern:@"^([^\\{\\}\n]*\\}{2})(?:.)*$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    }
    return self;
}

#pragma mark - Overrides

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    // Reset
    [attributedString removeAttribute:WMFSourceEditorCustomKeyHorizontalTemplate range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyVerticalTemplate range:range];
    
    [self.horizontalTemplateRegex enumerateMatchesInString:attributedString.string
                                                 options:0
                                                   range:range
                                              usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                  NSRange matchRange = [result rangeAtIndex:0];

                                                  if (matchRange.location != NSNotFound) {
                                                      [attributedString addAttributes:self.horizontalTemplateAttributes range:matchRange];
                                                  }
                                              }];
    
    [self.verticalStartTemplateRegex enumerateMatchesInString:attributedString.string
                                                 options:0
                                                   range:range
                                              usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                    NSRange fullMatch = [result rangeAtIndex:0];
                                                    NSRange openingTemplateRange = [result rangeAtIndex:1];

                                                    if (fullMatch.location != NSNotFound && openingTemplateRange.location != NSNotFound) {
                                                      [attributedString addAttributes:self.verticalTemplateAttributes range:openingTemplateRange];
                                                    }
                                              }];
    
    [self.verticalParameterTemplateRegex enumerateMatchesInString:attributedString.string
                                                 options:0
                                                   range:range
                                              usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                  NSRange matchRange = [result rangeAtIndex:0];

                                                  if (matchRange.location != NSNotFound) {
                                                      [attributedString addAttributes:self.verticalTemplateAttributes range:matchRange];
                                                  }
                                              }];
    
    [self.verticalEndTemplateRegex enumerateMatchesInString:attributedString.string
                                                 options:0
                                                   range:range
                                              usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        
                                                NSRange fullMatch = [result rangeAtIndex:0];
                                                NSRange closingTemplateRange = [result rangeAtIndex:1];

                                                if (fullMatch.location != NSNotFound && closingTemplateRange.location != NSNotFound) {
                                                  [attributedString addAttributes:self.verticalTemplateAttributes range:closingTemplateRange];
                                                }
        
                                              }];
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    NSMutableDictionary *mutHorizontalAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.horizontalTemplateAttributes];
    [mutHorizontalAttributes setObject:colors.purpleForegroundColor forKey:NSForegroundColorAttributeName];
    self.horizontalTemplateAttributes = [[NSDictionary alloc] initWithDictionary:mutHorizontalAttributes];
    
    NSMutableDictionary *mutVerticalAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.verticalTemplateAttributes];
    [mutVerticalAttributes setObject:colors.purpleForegroundColor forKey:NSForegroundColorAttributeName];
    self.verticalTemplateAttributes = [[NSDictionary alloc] initWithDictionary:mutVerticalAttributes];
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyHorizontalTemplate
                     inRange:range
                     options:nil
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.horizontalTemplateAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyVerticalTemplate
                     inRange:range
                     options:nil
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.verticalTemplateAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed for templates
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHorizontalTemplateInRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }
    
    __block BOOL isTemplate = NO;
    if (range.length == 0) {
        
        NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];
        
        if (attrs[WMFSourceEditorCustomKeyHorizontalTemplate] != nil) {
            isTemplate = YES;
        }
        
    } else {
        __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
        [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
            if (attrs[WMFSourceEditorCustomKeyHorizontalTemplate] != nil) {
                if (unionRange.location == NSNotFound) {
                    unionRange = loopRange;
                } else {
                    unionRange = NSUnionRange(unionRange, loopRange);
                }
                stop = YES;
            }
        }];
        
        if (NSEqualRanges(unionRange, range)) {
            isTemplate = YES;
        }
    }
    
    return isTemplate;
}

@end
