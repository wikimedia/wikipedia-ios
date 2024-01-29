#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WKSourceEditorColors, WKSourceEditorFonts, WKSourceEditorFormatter;
@protocol WKSourceEditorStorageDelegate;

@interface WKSourceEditorTextStorage : NSTextStorage

@property (nonatomic, weak) id<WKSourceEditorStorageDelegate> storageDelegate;
@property (nonatomic, assign) BOOL syntaxHighlightProcessingEnabled;

- (void)updateColorsAndFonts;

@end

NS_ASSUME_NONNULL_END
