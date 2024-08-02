#import "WMFSourceEditorFormatterSuperscript.h"
#import "WMFSourceEditorColors.h"

@interface WMFSourceEditorFormatterSuperscript ()

@property (nonatomic, strong) NSDictionary *superscriptAttributes;
@property (nonatomic, strong) NSDictionary *superscriptContentAttributes;
@property (nonatomic, strong) NSRegularExpression *superscriptRegex;

@end

@implementation WMFSourceEditorFormatterSuperscript

#pragma mark - Custom Attributed String Keys
NSString * const WMFSourceEditorCustomKeyContentSuperscript = @"WMFSourceEditorCustomKeyContentSuperscript";

- (instancetype)initWithColors:(WMFSourceEditorColors *)colors fonts:(WMFSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _superscriptAttributes = @{
            NSForegroundColorAttributeName: colors.greenForegroundColor,
            WMFSourceEditorCustomKeyColorGreen: [NSNumber numberWithBool:YES]
        };

        _superscriptContentAttributes = @{
            WMFSourceEditorCustomKeyContentSuperscript: [NSNumber numberWithBool:YES]
        };

        _superscriptRegex = [[NSRegularExpression alloc] initWithPattern:@"(<sup>)(.*?)(<\\/sup>)" options:0 error:nil];
    }

    return self;
}
- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }

    [attributedString removeAttribute:WMFSourceEditorCustomKeyContentSuperscript range:range];

    [self.superscriptRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange fullMatch = [result rangeAtIndex:0];
            NSRange openingRange = [result rangeAtIndex:1];
            NSRange contentRange = [result rangeAtIndex:2];
            NSRange closingRange = [result rangeAtIndex:3];

            if (openingRange.location != NSNotFound) {
                [attributedString addAttributes:self.superscriptAttributes range:openingRange];
            }

            if (contentRange.location != NSNotFound) {
                [attributedString addAttributes:self.superscriptContentAttributes range:contentRange];
            }

            if (closingRange.location != NSNotFound) {
                [attributedString addAttributes:self.superscriptAttributes range:closingRange];
            }
        }];
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }

    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.superscriptAttributes];
    [mutAttributes setObject:colors.greenForegroundColor forKey:NSForegroundColorAttributeName];
    self.superscriptAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];

    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyColorGreen
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.superscriptAttributes range:localRange];
            }
        }
    }];

}

#pragma mark - Public

- (BOOL)attributedString:(nonnull NSMutableAttributedString *)attributedString isSuperscriptInRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }
    
    __block BOOL isContentKey = NO;

   if (range.length == 0) {

       NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

       if (attrs[WMFSourceEditorCustomKeyContentSuperscript] != nil) {
           isContentKey = YES;
       } else {
           NSRange newRange = NSMakeRange(range.location - 1, 0);
           if (attrs[WMFSourceEditorCustomKeyColorGreen] && [self canEvaluateAttributedString:attributedString againstRange:newRange]) {
               attrs = [attributedString attributesAtIndex:newRange.location effectiveRange:nil];
               if (attrs[WMFSourceEditorCustomKeyContentSuperscript] != nil) {
                   isContentKey = YES;
               }
           }
       }

   } else {
       __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
       [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
           if (attrs[WMFSourceEditorCustomKeyContentSuperscript] != nil) {
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

@end
