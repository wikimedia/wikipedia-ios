#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WMFSourceEditorColors, WMFSourceEditorFonts, WMFSourceEditorFormatter;
@protocol WMFSourceEditorStorageDelegate;

@interface WMFSourceEditorTextStorage : NSTextStorage

@property (nonatomic, weak) id<WMFSourceEditorStorageDelegate> storageDelegate;
@property (nonatomic, assign) BOOL syntaxHighlightProcessingEnabled;

- (void)updateColorsAndFonts;

@end

NS_ASSUME_NONNULL_END
