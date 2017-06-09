#import <WMF/EventLoggingFunnel.h>

@interface WMFSuggestedPagesFunnel : EventLoggingFunnel

- (id)initWithArticle:(MWKArticle *)article
      suggestedTitles:(NSArray *)suggestedTitles;
- (void)logShown;
- (void)logClickedAtIndex:(NSUInteger)index;

@end
