#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WMFSourceEditorFormatter, WMFSourceEditorColors, WMFSourceEditorFonts;

@protocol WMFSourceEditorStorageDelegate
    @required
    @property (readonly) NSArray<WMFSourceEditorFormatter *> *formatters;
    @property (readonly) WMFSourceEditorColors *colors;
    @property (readonly) WMFSourceEditorFonts *fonts;
@end

NS_ASSUME_NONNULL_END
