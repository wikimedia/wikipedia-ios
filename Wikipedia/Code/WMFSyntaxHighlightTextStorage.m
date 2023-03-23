#import "WMFSyntaxHighlightTextStorage.h"
#import "NSMutableAttributedString+WikitextEditingExtensions.h"
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
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper boldKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper italicKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper boldAndItalicKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper linkKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper templateKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper refKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper refWithAttributesKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper refSelfClosingKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper superscriptKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper subscriptKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper underlineKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper strikethroughKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper h2Key] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper h3Key] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper h4Key] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper h5Key] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper h6Key] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper listBulletKey] range:searchRange];
    [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper listNumberKey] range:searchRange];

    [self addWikitextSyntaxFormattingWithSearchRange:searchRange fontSizeTraitCollection:self.fontSizeTraitCollection needsColors:YES theme: self.theme];
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
