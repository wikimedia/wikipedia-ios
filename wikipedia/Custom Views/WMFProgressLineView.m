

#import "WMFProgressLineView.h"

@interface WMFProgressLineView ()

@property (nonatomic, strong) UIView *progressBar;

@end

@implementation WMFProgressLineView


#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.frame = frame;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        self.progressBar = [[UIView alloc] init];
        self.progressBar.backgroundColor = [UIColor colorWithRed:0.106 green:0.682 blue:0.541 alpha:1];
        self.progress = 0.0;
        [self addSubview:self.progressBar];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    //whole pixels for non-retina screens
    frame.origin.y = ceilf(frame.origin.y);
    frame.size.height = floorf(frame.size.height);
    [super setFrame:frame];
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.progress = weakSelf.progress;
    });
}

#pragma mark - Progress

- (void)setProgressColor:(UIColor *)progressColor{
    self.progressBar.backgroundColor = progressColor;
}

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated{
    
    [self setProgress:progress animated:animated completion:NULL];
}

- (void)setProgress:(float)progress animated:(BOOL)animated completion:(dispatch_block_t)completion{
    
    _progress = (progress < 0) ? 0 :
				(progress > 1) ? 1 :
				progress;
    
    CGRect slice, remainder;
    CGRectDivide(self.bounds, &slice, &remainder, CGRectGetWidth(self.bounds) * _progress, CGRectMinXEdge);

    [CATransaction begin];
    
    [CATransaction setCompletionBlock:completion];

    if (!CGRectEqualToRect(self.progressBar.frame, slice)) {
        
        
        if(animated){
            
            [UIView animateWithDuration:0.2 animations:^{
                
                self.progressBar.frame = slice;
            }];
            
        }else{
            
            self.progressBar.frame = slice;
            
        }
    }
    
    [CATransaction commit];
}



@end
