#import "WKSourceEditorTextStorage.h"

@interface WKSourceEditorTextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *backingStore;

@end

@implementation WKSourceEditorTextStorage

- (nonnull instancetype)init {
    if (self = [super init]) {
        _backingStore = [[NSMutableAttributedString alloc] init];
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

    // TODO: syntax highlighting
    
    [super processEditing];
}

@end
