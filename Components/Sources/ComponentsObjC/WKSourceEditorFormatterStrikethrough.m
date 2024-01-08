#import "WKSourceEditorFormatterStrikethrough.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterStrikethrough ()

@property (nonatomic, strong) NSDictionary *strikethroughAttributes;
@property (nonatomic, strong) NSDictionary *strikethroughContentAttributes;
@property (nonatomic, strong) NSRegularExpression *strikethroughRegex;

@end

@implementation WKSourceEditorFormatterStrikethrough

#pragma mark - Custom Attributed String Keys

NSString * const WKSourceEditorCustomKeyContentStrikethrough = @"WKSourceEditorCustomKeyContentStrikethrough";

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _strikethroughAttributes = @{
            NSForegroundColorAttributeName: colors.greenForegroundColor,
            WKSourceEditorCustomKeyColorGreen: [NSNumber numberWithBool:YES]
        };
        
        _strikethroughContentAttributes = @{
            WKSourceEditorCustomKeyContentStrikethrough: [NSNumber numberWithBool:YES]
        };
        
        _strikethroughRegex = [[NSRegularExpression alloc] initWithPattern:@"(<s>)(\\s*.*?)(<\\/s>)" options:0 error:nil];
    }
    
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // Reset
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentStrikethrough range:range];
    
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
        
            if (contentRange.location != NSNotFound) {
                [attributedString addAttributes:self.strikethroughContentAttributes range:contentRange];
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

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isStrikethroughInRange:(NSRange)range {
    __block BOOL isContentKey = NO;

   if (range.length == 0) {

       if (attributedString.length > range.location) {
           NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

           if (attrs[WKSourceEditorCustomKeyContentStrikethrough] != nil) {
               isContentKey = YES;
           } else {
               // Edge case, check previous character if we are up against closing string
               if (attrs[WKSourceEditorCustomKeyColorGreen]) {
                   attrs = [attributedString attributesAtIndex:range.location - 1 effectiveRange:nil];
                   if (attrs[WKSourceEditorCustomKeyContentStrikethrough] != nil) {
                       isContentKey = YES;
                   }
               }
           }
       }

   } else {
       __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
       [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
           if (attrs[WKSourceEditorCustomKeyContentStrikethrough] != nil) {
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
