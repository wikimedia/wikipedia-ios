#import "WKSourceEditorTextStorage.h"
#import "WKSourceEditorFormatterBase.h"
#import "WKSourceEditorStorageDelegate.h"

@interface WKSourceEditorTextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *backingStore;
@property (nonatomic, assign) BOOL needsSyntaxHighlightingCalculation;

@end

@implementation WKSourceEditorTextStorage

- (nonnull instancetype)init {
    if (self = [super init]) {
        _backingStore = [[NSMutableAttributedString alloc] init];
        _needsSyntaxHighlightingCalculation = YES;
    }
    return self;
}

// MARK: - Overrides

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

- (void)processEditing {

    if (self.needsSyntaxHighlightingCalculation) {
        [self addSyntaxHighlightingToEditedRange:self.editedRange];
    }
    
    [super processEditing];
}

// MARK: - Public

- (void)updateColorsAndFonts {
    WKSourceEditorColors *colors = [self.storageDelegate colors];
    WKSourceEditorFonts *fonts = [self.storageDelegate fonts];
    
    self.needsSyntaxHighlightingCalculation = NO;
    [self beginEditing];
    NSRange allRange = NSMakeRange(0, self.backingStore.length);
    for (WKSourceEditorFormatter *formatter in [self.storageDelegate formatters]) {
        [formatter updateColors:colors inAttributedString:self inRange:allRange];
        [formatter updateFonts:fonts inAttributedString:self inRange:allRange];
    }
    
    [self endEditing];
    
    self.needsSyntaxHighlightingCalculation = YES;
}

// MARK: - Private

- (void)addSyntaxHighlightingToEditedRange:(NSRange)editedRange {
    
    // Extend range to entire line for reevaluation, not just what was edited
    NSRange extendedRange = NSUnionRange(editedRange, [self.backingStore.string lineRangeForRange:NSMakeRange(editedRange.location, 0)]);
    extendedRange = NSUnionRange(editedRange, [self.backingStore.string lineRangeForRange:NSMakeRange(NSMaxRange(editedRange), 0)]);
    [self addSyntaxHighlightingToExtendedRange:extendedRange];
}

- (void)addSyntaxHighlightingToExtendedRange:(NSRange)extendedRange {
    
    // reset old attributes
    [self removeAttribute:NSFontAttributeName range:extendedRange];
    [self removeAttribute:NSForegroundColorAttributeName range:extendedRange];
    [self removeAttribute:NSForegroundColorAttributeName range:extendedRange];
    
    for (WKSourceEditorFormatter *formatter in [self.storageDelegate formatters]) {
        [formatter addSyntaxHighlightingToAttributedString:self inRange:extendedRange];
    }
}

@end
