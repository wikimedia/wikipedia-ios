#import "WKSourceEditorFormatterComment.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterComment ()

@property (nonatomic, strong) NSDictionary *commentSyntaxAttributes;
@property (nonatomic, strong) NSDictionary *commentContentAttributes;
@property (nonatomic, strong) NSRegularExpression *commentRegex;

@end

@implementation WKSourceEditorFormatterComment

#pragma mark - Custom Attributed String Keys

NSString * const WKSourceEditorCustomKeyCommentSyntax = @"WKSourceEditorCustomKeyCommentSyntax";
NSString * const WKSourceEditorCustomKeyCommentContent = @"WKSourceEditorCustomKeyCommentContent";

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _commentSyntaxAttributes = @{
            NSForegroundColorAttributeName: colors.grayForegroundColor,
            WKSourceEditorCustomKeyCommentSyntax: [NSNumber numberWithBool:YES]
        };
        
        _commentContentAttributes = @{
            NSForegroundColorAttributeName: colors.grayForegroundColor,
            WKSourceEditorCustomKeyCommentContent: [NSNumber numberWithBool:YES]
        };

        _commentRegex = [[NSRegularExpression alloc] initWithPattern:@"(<!--)(.*?)(-->)" options:0 error:nil];
    }

    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    [attributedString removeAttribute:WKSourceEditorCustomKeyCommentSyntax range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyCommentContent range:range];
    
    [self.commentRegex enumerateMatchesInString:attributedString.string
                                        options:0
                                          range:range
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
            NSRange fullMatch = [result rangeAtIndex:0];
            NSRange openingRange = [result rangeAtIndex:1];
            NSRange contentRange = [result rangeAtIndex:2];
            NSRange closingRange = [result rangeAtIndex:3];

            if (openingRange.location != NSNotFound) {
                [attributedString addAttributes:self.commentSyntaxAttributes range:openingRange];
            }
        
            if (contentRange.location != NSNotFound) {
                [attributedString addAttributes:self.commentContentAttributes range:contentRange];
            }

            if (closingRange.location != NSNotFound) {
                [attributedString addAttributes:self.commentSyntaxAttributes range:closingRange];
            }
        }];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {

    NSMutableDictionary *mutSyntaxAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.commentSyntaxAttributes];
    [mutSyntaxAttributes setObject:colors.grayForegroundColor forKey:NSForegroundColorAttributeName];
    self.commentSyntaxAttributes = [[NSDictionary alloc] initWithDictionary:mutSyntaxAttributes];
    
    NSMutableDictionary *mutContentAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.commentContentAttributes];
    [mutContentAttributes setObject:colors.grayForegroundColor forKey:NSForegroundColorAttributeName];
    self.commentContentAttributes = [[NSDictionary alloc] initWithDictionary:mutContentAttributes];

    [attributedString enumerateAttribute:WKSourceEditorCustomKeyCommentSyntax
                                 inRange:range
                                 options:nil
                              usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.commentSyntaxAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyCommentContent
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

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    // No special font handling needed
}

#pragma mark - Public

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isCommentInRange:(NSRange)range {
    __block BOOL isContentKey = NO;

   if (range.length == 0) {

       if (attributedString.length > range.location) {
           NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];

           if (attrs[WKSourceEditorCustomKeyCommentContent] != nil) {
               isContentKey = YES;
           } else {
               // Edge case, check previous character if we are up against closing string
               if (attrs[WKSourceEditorCustomKeyCommentSyntax] && attributedString.length > range.location - 1) {
                   attrs = [attributedString attributesAtIndex:range.location - 1 effectiveRange:nil];
                   if (attrs[WKSourceEditorCustomKeyCommentContent] != nil) {
                       isContentKey = YES;
                   }
               }
           }
       }

   } else {
       __block NSRange unionRange = NSMakeRange(NSNotFound, 0);
       [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
           if (attrs[WKSourceEditorCustomKeyCommentContent] != nil) {
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
