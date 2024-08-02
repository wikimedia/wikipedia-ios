#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WKSourceEditorFormatter, WKSourceEditorColors, WKSourceEditorFonts;

@protocol WKSourceEditorStorageDelegate
    @required
    @property (readonly) NSArray<WKSourceEditorFormatter *> *formatters;
    @property (readonly) WKSourceEditorColors *colors;
    @property (readonly) WKSourceEditorFonts *fonts;
@end

NS_ASSUME_NONNULL_END
