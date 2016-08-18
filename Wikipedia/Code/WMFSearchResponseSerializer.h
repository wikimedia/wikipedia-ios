#import "WMFApiJsonResponseSerializer.h"

@interface WMFSearchResponseSerializer : WMFApiJsonResponseSerializer

@property (nonatomic, weak) Class searchResultClass;

@end
