#import <Foundation/Foundation.h>

@interface WMFBoringNavigationTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) UINavigationControllerOperation operation;

@end
