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

#endif
