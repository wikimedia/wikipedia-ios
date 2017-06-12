@import WMF.EventLoggingFunnel;

@class MWKArticle;

@interface WMFShareFunnel : EventLoggingFunnel

- (id)initWithArticle:(MWKArticle *)article;

- (void)logHighlight;
- (void)logShareButtonTappedResultingInSelection:(NSString *)selection;
- (void)logAbandonedAfterSeeingShareAFact;
- (void)logShareAsImageTapped;
- (void)logShareAsTextTapped;

/*! Log the final outcome of the share as a failure
 * @param shareMethod System provided share application string if known
 */
- (void)logShareFailedWithShareMethod:(NSString *)shareMethod;

/*! Log the final outcome of the share as a success
 * @param shareMethod System provided share application string if known
 */
- (void)logShareSucceededWithShareMethod:(NSString *)shareMethod;

@end
