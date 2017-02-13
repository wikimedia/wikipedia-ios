#ifndef WMFTableOfContentsDisplay_h
#define WMFTableOfContentsDisplay_h

typedef NS_ENUM(NSUInteger, WMFTableOfContentsDisplaySide) {
    WMFTableOfContentsDisplaySideLeft,
    WMFTableOfContentsDisplaySideRight,
    WMFTableOfContentsDisplaySideCenter
};

typedef NS_ENUM(NSUInteger, WMFTableOfContentsDisplayMode) {
    WMFTableOfContentsDisplayModeModal,
    WMFTableOfContentsDisplayModeInline
};

typedef NS_ENUM(NSUInteger, WMFTableOfContentsDisplayState) {
    WMFTableOfContentsDisplayStateInlineVisible,
    WMFTableOfContentsDisplayStateInlineHidden,
    WMFTableOfContentsDisplayStateModalVisible,
    WMFTableOfContentsDisplayStateModalHidden
};

typedef NS_ENUM(NSUInteger, WMFTableOfContentsDisplayStyle) {
    WMFTableOfContentsDisplayStyleOld = 0,
    WMFTableOfContentsDisplayStyleCurrent = 1,
    WMFTableOfContentsDisplayStyleNext = 2
};

#endif
