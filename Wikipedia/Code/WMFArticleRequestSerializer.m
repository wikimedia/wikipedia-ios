#import "WMFArticleRequestSerializer.h"
@import WMF;

@implementation WMFArticleRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *serializedParams = [self paramsForURL:(NSURL *)parameters];

    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSMutableDictionary *)paramsForURL:(NSURL *)url {
    NSString *title = [url wmf_title];
    if (!title) {
        DDLogError(@"Missing title for article request serialization: %@", url);
        return @{}.mutableCopy;
    }

    NSNumber *thumbnailWidth = [[UIScreen mainScreen] wmf_leadImageWidthForScale];
    if (!thumbnailWidth) {
        DDLogError(@"Missing thumbnail width for article request serialization: %@", url);
        thumbnailWidth = @640;
    }

    NSMutableDictionary *params = @{
        @"format": @"json",
        @"action": @"mobileview",
        @"sectionprop": WMFJoinedPropertyParameters(@[@"toclevel", @"line", @"anchor", @"level", @"number",
                                                      @"fromtitle", @"index"]),
        @"noheadings": @"true",
        @"sections": @"all",
        @"page": title,
        @"thumbwidth": thumbnailWidth,
        @"prop": WMFJoinedPropertyParameters(@[@"sections", @"text", @"lastmodified", @"lastmodifiedby", @"languagecount", @"id", @"protection", @"editable", @"displaytitle", @"thumb", @"description", @"image", @"revision", @"namespace", @"pageprops"]),
        @"pageprops": @"wikibase_item"
        //@"pilicense": @"any"
    }
                                      .mutableCopy;

    return params;
}

@end
