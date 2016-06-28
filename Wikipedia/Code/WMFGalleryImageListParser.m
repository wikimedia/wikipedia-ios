#import "WMFGalleryImageListParser.h"
#import "WMFImageTag.h"
#import "WMFImageTag+TargetImageWidthURL.h"
#import <BlocksKit/BlocksKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFGalleryImageListParser() <NSXMLParserDelegate>

@property (nonatomic, strong, nullable) NSMutableArray<NSDictionary*>* parsedImgTagAttributeDicts;

@end

@implementation WMFGalleryImageListParser

- (nullable NSArray<NSURL*>*)parseGalleryImageURLsFromHTMLString:(NSString*)HTMLString targetWidth:(NSUInteger)targetWidth;{

    HTMLString = [HTMLString copy];

    // NSXMLParser will update parsedImgTagAttributeDicts with a dictionary for each img tag it parses.
    self.parsedImgTagAttributeDicts = [[NSMutableArray alloc] init];
    
    // First reduce HTMLString to only image tags so other funky/malformed html won't choke NSXMLParser.
    NSString* imgTagsHtml = [self imgTagsOnlyFromHTMLString:HTMLString];
    
    // Then use NSXMLParser to auto-extract tag attribute key/values to a dictionary for each image tag.
    [self parseStringOfImgTags:imgTagsHtml];
    
    // Map parsedImgTagAttributeDicts to image tag model objects.
    NSArray<WMFImageTag*>* imageTagModels = [self.parsedImgTagAttributeDicts bk_map:^id(NSDictionary* tagDict){
        return [[WMFImageTag alloc] initWithSrc:tagDict[@"src"]
                                         srcset:tagDict[@"srcset"]
                                            alt:tagDict[@"alt"]
                                          width:tagDict[@"width"]
                                         height:tagDict[@"height"]
                                  dataFileWidth:tagDict[@"data-file-width"]
                                 dataFileHeight:tagDict[@"data-file-height"]];
    }];
    
    NSArray<NSURL*>* imageTagURLs = [[imageTagModels bk_select:^BOOL(WMFImageTag* tag){
        return [tag isWideEnoughForGallery];
    }] bk_map:^id(WMFImageTag* tag){
        return [tag urlForTargetWidth:targetWidth];
    }];
    
    return imageTagURLs;
}

- (void)parseStringOfImgTags:(NSString*)imgTags {
    // NSXMLParser wants a single root element.
    imgTags = [NSString stringWithFormat:@"<base>%@</base>", imgTags];

    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:[imgTags dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = self;
    [parser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict {
    [self.parsedImgTagAttributeDicts addObject:attributeDict];
}

- (NSString*)imgTagsOnlyFromHTMLString:(NSString*)HTMLString{
    static NSRegularExpression* imgTagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imgTagRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:<img\\s)(?:[^>]*)(?:>)"
                                                                options:NSRegularExpressionCaseInsensitive
                                                                  error:nil];
    });
    NSArray<NSTextCheckingResult *>* matches = [imgTagRegex matchesInString:HTMLString options:0 range:NSMakeRange(0, HTMLString.length)];
    return [[matches bk_map:^id(NSTextCheckingResult* match){
        return [HTMLString substringWithRange:match.range];
    }] componentsJoinedByString:@""];
}

@end

NS_ASSUME_NONNULL_END
