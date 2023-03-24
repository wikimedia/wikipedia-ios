#import "WMFSyntaxHighlightTextStorage.h"
#import "Wikipedia-Swift.h"

@interface WMFSyntaxHighlightTextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *backingStore;

@end

@implementation WMFSyntaxHighlightTextStorage

- (instancetype)init {
    if (self = [super init]) {
        _backingStore = [[NSMutableAttributedString alloc] init];
        _calculateSyntaxHighlightsUponEditEnabled = YES;
    }
    return self;
}

- (NSString *)string {
    return self.backingStore.string;
}

- (NSDictionary<NSAttributedStringKey, id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [self.backingStore attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self beginEditing];
    [self.backingStore replaceCharactersInRange:range withString:str];
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:str.length - range.length];
    [self endEditing];
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range {
    [self beginEditing];
    [self.backingStore setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)removeAttribute:(NSAttributedStringKey)name rangeValues:(NSArray<NSValue *> *)rangeValues {
    [self beginEditing];
    for (NSValue *rangeValue in rangeValues) {
        [self.backingStore removeAttribute:name range:rangeValue.rangeValue];
        [self edited:NSTextStorageEditedAttributes range:rangeValue.rangeValue changeInLength:0];
    }
    
    [self endEditing];
}

- (void)addAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs rangeValues:(NSArray<NSValue *> *)rangeValues {
    [self beginEditing];
    for (NSValue *rangeValue in rangeValues) {
        [self.backingStore addAttributes:attrs range:rangeValue.rangeValue];
        [self edited:NSTextStorageEditedAttributes range:rangeValue.rangeValue changeInLength:0];
    }
    
    [self endEditing];
}

- (void)applyStylesToRange:(NSRange)searchRange {
    
    [self removeAttribute:NSFontAttributeName range:searchRange];
    [self removeAttribute:NSForegroundColorAttributeName range:searchRange];
    [self removeAttribute:NSForegroundColorAttributeName range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextBold range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextItalic range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextBoldAndItalic range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextLink range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextImage range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextTemplate range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextRef range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextRefWithAttributes range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextRefSelfClosing range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextSuperscript range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextSubscript range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextComment range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextUnderline range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextStrikethrough range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextH2 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextH3 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextH4 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextH5 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextH6 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextBullet range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyWikitextNumber range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyColorLink range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyColorComment range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyColorTempate range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyColorHtmlTag range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyColorShorthand range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontBold range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontItalic range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontBoldItalic range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontH2 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontH3 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontH4 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontH5 range:searchRange];
    [self removeAttribute:kCustomAttributedStringKeyFontH6 range:searchRange];
    
    [self.mutableAttributedStringHelper addWikitextSyntaxFormattingToNSMutableAttributedString:self searchRange:searchRange theme:self.theme];
}

- (void)performReplacementsForRange:(NSRange)changedRange {
    NSRange extendedRange = NSUnionRange(changedRange, [self.backingStore.string lineRangeForRange:NSMakeRange(changedRange.location, 0)]);
    extendedRange = NSUnionRange(changedRange, [self.backingStore.string lineRangeForRange:NSMakeRange(NSMaxRange(changedRange), 0)]);
    [self applyStylesToRange:extendedRange];
}

- (void)processEditing {
    if (self.calculateSyntaxHighlightsUponEditEnabled) {
        [self performReplacementsForRange:self.editedRange];
    }
    [super processEditing];
}

- (void)updateFontSizeWithPreferredContentSize: (UIContentSizeCategory)preferredContentSizeCategory {
    
    NSInteger standardSize;
    if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraSmall]) {
        standardSize = 10;
    } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategorySmall]) {
        standardSize = 12;
    }
    else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryMedium]) {
        standardSize = 14;
   }
    else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryLarge]) {
        standardSize = 16;
   } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraLarge]) {
       standardSize = 18;
   }
   else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
       standardSize = 20;
   } else {
       standardSize = 16;
   }
    
    UIFont *standardFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:standardSize]];
    UIFontDescriptor *boldFontDescriptor = [standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFontDescriptor *italicFontDescriptor = [standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    UIFontDescriptor *boldItalicFontDescriptor = [standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:standardFont.pointSize];
    UIFont *italicFont = [UIFont fontWithDescriptor:italicFontDescriptor size:standardFont.pointSize];
    UIFont *boldItalicFont = [UIFont fontWithDescriptor:boldItalicFontDescriptor size:standardFont.pointSize];

    UIFont *h2Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 10]];
    UIFont *h3Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 8]];
    UIFont *h4Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 6]];
    UIFont *h5Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 4]];
    UIFont *h6Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 2]];
    
    self.calculateSyntaxHighlightsUponEditEnabled = NO;
    [self beginEditing];
    NSRange allRange = NSMakeRange(0, self.backingStore.length);
    [self addAttribute:NSFontAttributeName value:standardFont range:allRange];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontBold
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:boldFont range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontItalic
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:italicFont range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontBoldItalic
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:boldItalicFont range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontH2
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:h2Font range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontH3
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:h3Font range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontH4
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:h4Font range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontH5
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:h5Font range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyFontH6
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSFontAttributeName value:h6Font range:range];
            }
        }
    }];
    
    [self endEditing];
    self.calculateSyntaxHighlightsUponEditEnabled = YES;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.calculateSyntaxHighlightsUponEditEnabled = NO;
    [self beginEditing];
    NSRange allRange = NSMakeRange(0, self.backingStore.length);
    [self addAttribute:NSForegroundColorAttributeName value:theme.colors.primaryText range:allRange];
    
    [self enumerateAttribute:kCustomAttributedStringKeyColorTempate
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSForegroundColorAttributeName value:theme.colors.nativeEditorTemplate range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyColorHtmlTag
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSForegroundColorAttributeName value:theme.colors.nativeEditorHtmlTag range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyColorLink
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSForegroundColorAttributeName value:theme.colors.nativeEditorLink range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyColorComment
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSForegroundColorAttributeName value:theme.colors.nativeEditorComment range:range];
            }
        }
    }];
    
    [self enumerateAttribute:kCustomAttributedStringKeyColorShorthand
                     inRange:allRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [self addAttribute:NSForegroundColorAttributeName value:theme.colors.nativeEditorShorthand range:range];
            }
        }
    }];
    
    [self endEditing];
    self.calculateSyntaxHighlightsUponEditEnabled = YES;
}

- (void)applyFontSizeTraitCollection:(UITraitCollection *)fontSizeTraitCollection {
    self.fontSizeTraitCollection = fontSizeTraitCollection;
    NSRange allRange = NSMakeRange(0, self.backingStore.length);
    //[self applyStylesToRange:allRange];
    
    //more performant?
    
    UIFont *normalFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:self.fontSizeTraitCollection];
    NSDictionary *normalAttributes = @{
        NSFontAttributeName: normalFont,
    };
    [self addAttributes:normalAttributes range:allRange];
}

@end
