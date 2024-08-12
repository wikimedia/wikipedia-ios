#import "WMFSourceEditorFormatterComment.h"
#import "WMFSourceEditorColors.h"

@interface WMFSourceEditorFormatterComment ()

@property (nonatomic, strong) NSDictionary *commentMarkupAttributes;
@property (nonatomic, strong) NSDictionary *commentContentAttributes;
@property (nonatomic, strong) NSRegularExpression *commentRegex;

@end

@implementation WMFSourceEditorFormatterComment

#pragma mark - Custom Attributed String Keys

NSString * const WMFSourceEditorCustomKeyCommentMarkup = @"WMFSourceEditorCustomKeyCommentMarkup";
NSString * const WMFSourceEditorCustomKeyCommentContent = @"WMFSourceEditorCustomKeyCommentContent";

- (instancetype)initWithColors:(WMFSourceEditorColors *)colors fonts:(WMFSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _commentMarkupAttributes = @{
            NSForegroundColorAttributeName: colors.grayForegroundColor,
            WMFSourceEditorCustomKeyCommentMarkup: [NSNumber numberWithBool:YES]
        };
        
        _commentContentAttributes = @{
            NSForegroundColorAttributeName: colors.grayForegroundColor,
            WMFSourceEditorCustomKeyCommentContent: [NSNumber numberWithBool:YES]
        };

        _commentRegex = [[NSRegularExpression alloc] initWithPattern:@"(<!--)(.*?)(-->)" options:0 error:nil];
    }

    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    [attributedString removeAttribute:WMFSourceEditorCustomKeyCommentMarkup range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyCommentContent range:range];
    
    [self.commentRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange fullMatch = [result rangeAtIndex:0];
            NSRange openingRange = [result rangeAtIndex:1];
            NSRange contentRange = [result rangeAtIndex:2];
            NSRange closingRange = [result rangeAtIndex:3];

            if (openingRange.location != NSNotFound) {
                [attributedString addAttributes:self.commentMarkupAttributes range:openingRange];
            }
        
            if (contentRange.location != NSNotFound) {
                [attributedString addAttributes:self.commentContentAttributes range:contentRange];
            }

            if (closingRange.location != NSNotFound) {
                [attributedString addAttributes:self.commentMarkupAttributes range:closingRange];
            }
        }];
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    NSMutableDictionary *mutMarkupAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.commentMarkupAttributes];
    [mutMarkupAttributes setObject:colors.grayForegroundColor forKey:NSForegroundColorAttributeName];
    self.commentMarkupAttributes = [[NSDictionary alloc] initWithDictionary:mutMarkupAttributes];
    
    NSMutableDictionary *mutContentAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.commentContentAttributes];
    [mutContentAttributes setObject:colors.grayForegroundColor forKey:NSForegroundColorAttributeName];
    self.commentContentAttributes = [[NSDictionary alloc] initWithDictionary:mutContentAttributes];
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }

    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyCommentMarkup
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.commentMarkupAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WMFSourceEditorCustomKeyCommentContent
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.commentContentAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isCommentInRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return NO;
    }
    
    __block BOOL isContentKey = NO;

   if (range.length == 0) {

       if (attributedString.length > range.location) {
           NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

           if (attrs[WMFSourceEditorCustomKeyCommentContent] != nil) {
               isContentKey = YES;
           } else {
               // Edge case, check previous character if we are up against closing string
               NSRange newRange = NSMakeRange(range.location - 1, 0);
               if (attrs[WMFSourceEditorCustomKeyCommentMarkup] && [self canEvaluateAttributedString:attributedString againstRange:newRange]) {
                   attrs = [attributedString attributesAtIndex:newRange.location effectiveRange:nil];
                   if (attrs[WMFSourceEditorCustomKeyCommentContent] != nil) {
                       isContentKey = YES;
                   }
               }
           }
       }

   } else {
       __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
       [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
           if (attrs[WMFSourceEditorCustomKeyCommentContent] != nil) {
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
