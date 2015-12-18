
#import "WMFArticleResponseSerializer.h"
#import <Mantle/Mantle.h>
#import "WMFFixtureRecording.h"
#import "NSURL+Extras.h"

@implementation WMFArticleResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse*)response
                           data:(NSData*)data
                          error:(NSError* __autoreleasing*)error {
    NSDictionary* JSON        = [super responseObjectForResponse:response data:data error:error];
    NSDictionary* articleJSON = JSON[@"mobileview"];

    WMFRecordDataFixture(data,
                         [@"MobileView" stringByAppendingPathComponent:response.URL.host],
                         [[response.URL wmf_valueForQueryKey:@"page"] stringByAppendingPathExtension:@"json"]);

    /* TODO: actually map the contents. The issue here is that our data model revolves around "MWKTitle",
     * when in fact, the mobileview resppnse knows nothing about this concept. Meaning we can't parse an
     * MWKTitle from this reponse. And therefore cannot get the cached article from the data store.
     * Without significant data layer changes, we cannot move the serialization here where it belongs.
     * For now, continue to handle it in the layer above (Fetchers).
     *
     * When ready, add a "MWKDataStore" property or if post-CoreData, add a NSmanagedObjectContext property.
     */
    return articleJSON;
}

@end
