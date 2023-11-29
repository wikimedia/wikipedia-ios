#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WKSourceEditorColors, WKSourceEditorFonts, WKSourceEditorFormatter;
@protocol WKSourceEditorStorageDelegate;

@interface WKSourceEditorTextStorage : NSTextStorage

@property (nonatomic, weak) id<WKSourceEditorStorageDelegate> storageDelegate;

- (void)updateColorsAndFonts;

@end

NS_ASSUME_NONNULL_END
