#import "WKSourceEditorFormatterSubscript.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterSubscript ()

@property (nonatomic, strong) NSDictionary *subscriptAttributes;
@property (nonatomic, strong) NSDictionary *subscriptContentAttributes;
@property (nonatomic, strong) NSRegularExpression *subscriptRegex;

@end

@implementation WKSourceEditorFormatterSubscript

#pragma mark - Custom Attributed String Keys
NSString * const WKSourceEditorCustomKeyContentSubscript = @"WKSourceEditorCustomKeyContentSubscript";

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _subscriptAttributes = @{
            NSForegroundColorAttributeName: colors.greenForegroundColor,
            WKSourceEditorCustomKeyColorGreen: [NSNumber numberWithBool:YES]
        };

        _subscriptContentAttributes = @{
            WKSourceEditorCustomKeyContentSubscript: [NSNumber numberWithBool:YES]
        };

        _subscriptRegex = [[NSRegularExpression alloc] initWithPattern:@"(<sub>)(.*?)(<\\/sub>)" options:0 error:nil];

    }

    return self;
}
- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }

    [attributedString removeAttribute:WKSourceEditorCustomKeyContentSubscript range:range];

    [self.subscriptRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange fullMatch = [result rangeAtIndex:0];
            NSRange openingRange = [result rangeAtIndex:1];
            NSRange contentRange = [result rangeAtIndex:2];
            NSRange closingRange = [result rangeAtIndex:3];

            if (openingRange.location != NSNotFound) {
                [attributedString addAttributes:self.subscriptAttributes range:openingRange];
            }

            if (contentRange.location != NSNotFound) {
                [attributedString addAttributes:self.subscriptContentAttributes range:contentRange];
            }

            if (closingRange.location != NSNotFound) {
                [attributedString addAttributes:self.subscriptAttributes range:closingRange];
            }
        }];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.subscriptAttributes];
    [mutAttributes setObject:colors.greenForegroundColor forKey:NSForegroundColorAttributeName];
    self.subscriptAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }

    [attributedString enumerateAttribute:WKSourceEditorCustomKeyColorGreen
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.subscriptAttributes range:localRange];
            }
        }
    }];

}

#pragma mark - Public

- (BOOL)attributedString:(nonnull NSMutableAttributedString *)attributedString isSubscriptInRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }
    
    __block BOOL isContentKey = NO;

   if (range.length == 0) {

       NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

       if (attrs[WKSourceEditorCustomKeyContentSubscript] != nil) {
           isContentKey = YES;
       } else {
           NSRange newRange = NSMakeRange(range.location - 1, 0);
           if (attrs[WKSourceEditorCustomKeyColorGreen] && [self canEvaluateAttributedString:attributedString againstRange:newRange]) {
               attrs = [attributedString attributesAtIndex:newRange.location effectiveRange:nil];
               if (attrs[WKSourceEditorCustomKeyContentSubscript] != nil) {
                   isContentKey = YES;
               }
           }
       }

   } else {
       __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
       [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
           if (attrs[WKSourceEditorCustomKeyContentSubscript] != nil) {
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

