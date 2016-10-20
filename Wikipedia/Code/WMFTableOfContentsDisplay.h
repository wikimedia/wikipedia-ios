#ifndef WMFTableOfContentsDisplay_h
#define WMFTableOfContentsDisplay_h

typedef enum : NSUInteger {
    WMFTableOfContentsDisplaySideLeft,
    WMFTableOfContentsDisplaySideRight,
    WMFTableOfContentsDisplaySideCenter
} WMFTableOfContentsDisplaySide;

typedef enum : NSUInteger {
    WMFTableOfContentsDisplayModeModal,
    WMFTableOfContentsDisplayModeInline
} WMFTableOfContentsDisplayMode;

typedef enum : NSUInteger {
    WMFTableOfContentsDisplayStateInlineVisible,
    WMFTableOfContentsDisplayStateInlineHidden,
    WMFTableOfContentsDisplayStateModalVisible,
    WMFTableOfContentsDisplayStateModalHidden
} WMFTableOfContentsDisplayState;


typedef enum : NSInteger {
    WMFTableOfContentsDisplayStyleOld = 0,
    WMFTableOfContentsDisplayStyleCurrent = 1,
    WMFTableOfContentsDisplayStyleNext = 2
} WMFTableOfContentsDisplayStyle;

#endif
