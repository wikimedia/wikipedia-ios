#import "WKSourceEditorFormatterReference.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterReference ()
@property (nonatomic, strong) NSDictionary *refAttributes;
@property (nonatomic, strong) NSDictionary *refEmptyAttributes;
@property (nonatomic, strong) NSDictionary *refContentAttributes;

@property (nonatomic, strong) NSRegularExpression *refHorizontalRegex;
@property (nonatomic, strong) NSRegularExpression *refOpenRegex;
@property (nonatomic, strong) NSRegularExpression *refCloseRegex;
@property (nonatomic, strong) NSRegularExpression *refEmptyRegex;
@end

@implementation WKSourceEditorFormatterReference

#pragma mark - Custom Attributed String Keys

NSString * const WKSourceEditorCustomKeyContentReference = @"WKSourceEditorCustomKeyContentReference";

#pragma mark - Overrides

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _refAttributes = @{
            NSForegroundColorAttributeName: colors.greenForegroundColor,
            WKSourceEditorCustomKeyColorGreen: [NSNumber numberWithBool:YES]
        };
        
        _refEmptyAttributes = @{
            NSForegroundColorAttributeName: colors.greenForegroundColor,
            WKSourceEditorCustomKeyColorGreen: [NSNumber numberWithBool:YES]
        };
        
        _refContentAttributes = @{
            WKSourceEditorCustomKeyContentReference: [NSNumber numberWithBool:YES]
        };
        
        _refHorizontalRegex = [[NSRegularExpression alloc] initWithPattern:@"(<ref(?:[^\\/>]+?)?>)(.*?)(<\\/ref>)" options:0 error:nil];
        _refOpenRegex = [[NSRegularExpression alloc] initWithPattern:@"<ref(?:[^\\/>]+?)?>" options:0 error:nil];
        _refCloseRegex = [[NSRegularExpression alloc] initWithPattern:@"<\\/ref>" options:0 error:nil];
        _refEmptyRegex = [[NSRegularExpression alloc] initWithPattern:@"<ref[^>]+?\\/>" options:0 error:nil];
    }
    
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    // Reset
    [attributedString removeAttribute:WKSourceEditorCustomKeyContentReference range:range];
    
    [self.refHorizontalRegex enumerateMatchesInString:attributedString.string
                                    options:0
                                      range:range
                                 usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        NSRange fullMatch = [result rangeAtIndex:0];
        NSRange openingRange = [result rangeAtIndex:1];
        NSRange contentRange = [result rangeAtIndex:2];
        NSRange closingRange = [result rangeAtIndex:3];
        
        if (openingRange.location != NSNotFound) {
            [attributedString addAttributes:self.refAttributes range:openingRange];
        }
        
        if (contentRange.location != NSNotFound) {
            [attributedString addAttributes:self.refContentAttributes range:contentRange];
        }
        
        if (closingRange.location != NSNotFound) {
            [attributedString addAttributes:self.refAttributes range:closingRange];
        }
    }];
    
    [self.refEmptyRegex enumerateMatchesInString:attributedString.string
                                         options:0
                                           range:range
                                      usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        NSRange fullMatch = [result rangeAtIndex:0];
        
        if (fullMatch.location != NSNotFound) {
            [attributedString addAttributes:self.refAttributes range:fullMatch];
        }
    }];
    
    // refOpenAndClose regex doesn't match everything. This scoops up extra open and closing ref tags that do not have a matching tag on the same line
    
    [self.refOpenRegex enumerateMatchesInString:attributedString.string
                                         options:0
                                           range:range
                                      usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        NSRange fullMatch = [result rangeAtIndex:0];
        
        if (fullMatch.location != NSNotFound) {
            [attributedString addAttributes:self.refAttributes range:fullMatch];
        }
    }];
    
    [self.refCloseRegex enumerateMatchesInString:attributedString.string
                                         options:0
                                           range:range
                                      usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        NSRange fullMatch = [result rangeAtIndex:0];
        
        if (fullMatch.location != NSNotFound) {
            [attributedString addAttributes:self.refAttributes range:fullMatch];
        }
    }];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.refAttributes];
    [mutAttributes setObject:colors.greenForegroundColor forKey:NSForegroundColorAttributeName];
    self.refAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
    
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
                [attributedString addAttributes:self.refAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed for references
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHorizontalReferenceInRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }
    
    __block BOOL isContentKey = NO;

   if (range.length == 0) {

       NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

       if (attrs[WKSourceEditorCustomKeyContentReference] != nil) {
           isContentKey = YES;
       } else {
           // Edge case, check previous character if we are up against closing string
           NSRange newRange = NSMakeRange(range.location - 1, 0);
           if (attrs[WKSourceEditorCustomKeyColorGreen] && [self canEvaluateAttributedString:attributedString againstRange:newRange]) {
               attrs = [attributedString attributesAtIndex:newRange.location effectiveRange:nil];
               if (attrs[WKSourceEditorCustomKeyContentReference] != nil) {
                   isContentKey = YES;
               }
           }
       }

   } else {
       __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
       [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
           if (attrs[WKSourceEditorCustomKeyContentReference] != nil) {
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
