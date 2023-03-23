#import "WMFSyntaxHighlightTextStorage.h"
#import "Wikipedia-Swift.h"

@interface WMFSyntaxHighlightTextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *backingStore;

@end

@implementation WMFSyntaxHighlightTextStorage

- (instancetype)init {
    if (self = [super init]) {
        self.backingStore = [[NSMutableAttributedString alloc] init];
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

    [self.mutableAttributedStringHelper addWikitextSyntaxFormattingToNSMutableAttributedString:self searchRange:searchRange fontSizeTraitCollection:self.fontSizeTraitCollection needsColors:YES theme:self.theme];
}

- (void)performReplacementsForRange:(NSRange)changedRange {
    NSRange extendedRange = NSUnionRange(changedRange, [self.backingStore.string lineRangeForRange:NSMakeRange(changedRange.location, 0)]);
    extendedRange = NSUnionRange(changedRange, [self.backingStore.string lineRangeForRange:NSMakeRange(NSMaxRange(changedRange), 0)]);
    [self applyStylesToRange:extendedRange];
}

- (void)processEditing {
    [self performReplacementsForRange:self.editedRange];
    [super processEditing];
}

- (void)applyTheme:(WMFTheme *)theme { 
    self.theme = theme;
    NSRange allRange = NSMakeRange(0, self.backingStore.length);
    [self applyStylesToRange:allRange];
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
