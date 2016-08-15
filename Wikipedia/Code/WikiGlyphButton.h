#import <UIKit/UIKit.h>

@class WikiGlyphLabel;

@interface WikiGlyphButton : UIView

@property (strong, nonatomic) WikiGlyphLabel* label;

@property (strong, nonatomic) UIColor* color;

@property (nonatomic) BOOL enabled;

@end
