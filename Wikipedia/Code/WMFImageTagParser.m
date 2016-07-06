#import "WMFImageTagParser.h"
#import "WMFImageTag.h"
#import "WMFImageTagList.h"
#import <BlocksKit/BlocksKit.h>
#import "WMFImageURLParsing.h"

NS_ASSUME_NONNULL_BEGIN


@interface NSString (WMFImageTagParser)

- (NSString*)wmf_stringWithPercentEncodedTagAttributeValues;

@end

@implementation NSString (WMFImageTagParser)

- (NSString*)wmf_stringWithPercentEncodedTagAttributeValues {
    __block NSString*previousIntraQuoteStr = @"";
    return [[[self componentsSeparatedByString:@"\""] bk_map:^NSString*(NSString* intraQuoteStr){
        if ([previousIntraQuoteStr hasSuffix:@"="]) {
            intraQuoteStr = [intraQuoteStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        }
        previousIntraQuoteStr = intraQuoteStr;
        return intraQuoteStr;
    }] componentsJoinedByString:@"\""];
}

@end



@interface WMFImageTagParser () <NSXMLParserDelegate>

@property (nonatomic, strong, nullable) NSMutableArray<NSDictionary*>* parsedImgTagAttributeDicts;

@property (nonatomic, strong, nullable) NSString* leadImageNormalizedFilename;

@end

@implementation WMFImageTagParser

- (WMFImageTagList*)imageTagListFromParsingHTMLString:(NSString*)HTMLString withLeadImageURL:(nullable NSURL*)leadImageURL {
    HTMLString = [HTMLString copy];

    // NSXMLParser will update parsedImgTagAttributeDicts with a dictionary for each img tag it parses.
    self.parsedImgTagAttributeDicts = [[NSMutableArray alloc] init];

    // First reduce HTMLString to only image tags so other funky/malformed html won't choke NSXMLParser.
    NSString* imgTagsHtml = [self imgTagsOnlyFromHTMLString:HTMLString];

    self.leadImageNormalizedFilename = WMFParseUnescapedNormalizedImageNameFromSourceURL(leadImageURL.absoluteString);
    
    // Then use NSXMLParser to auto-extract tag attribute key/values to a dictionary for each image tag.
    [self parseStringOfImgTags:imgTagsHtml];

    // Map parsedImgTagAttributeDicts to image tag model objects.
    NSArray<WMFImageTag*>* imageTags = [self.parsedImgTagAttributeDicts bk_map:^id (NSDictionary* tagDict){
        return [[WMFImageTag alloc] initWithSrc:[tagDict[@"src"] stringByRemovingPercentEncoding]
                                         srcset:[tagDict[@"srcset"] stringByRemovingPercentEncoding]
                                            alt:[tagDict[@"alt"] stringByRemovingPercentEncoding]
                                          width:[tagDict[@"width"] stringByRemovingPercentEncoding]
                                         height:[tagDict[@"height"] stringByRemovingPercentEncoding]
                                  dataFileWidth:[tagDict[@"data-file-width"] stringByRemovingPercentEncoding]
                                 dataFileHeight:[tagDict[@"data-file-height"] stringByRemovingPercentEncoding]];
    }];

    return [[WMFImageTagList alloc] initWithImageTags:imageTags];
}

- (WMFImageTagList*)imageTagListFromParsingHTMLString:(NSString*)HTMLString {
    return [self imageTagListFromParsingHTMLString:HTMLString withLeadImageURL:nil];
}

- (void)parseStringOfImgTags:(NSString*)imgTags {
    // NSXMLParser wants a single root element.
    imgTags = [NSString stringWithFormat:@"<base>%@</base>", imgTags];

    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:[imgTags dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = self;
    [parser parse];
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(nullable NSString*)namespaceURI qualifiedName:(nullable NSString*)qName attributes:(NSDictionary<NSString*, NSString*>*)attributeDict {
    if ([[elementName lowercaseString] isEqualToString:@"img"]) {
        if (self.leadImageNormalizedFilename && [WMFParseUnescapedNormalizedImageNameFromSourceURL([attributeDict[@"src"] stringByRemovingPercentEncoding]) isEqualToString:self.leadImageNormalizedFilename]) { //check if this is the image we want first in the list by comparing filenames
           [self.parsedImgTagAttributeDicts insertObject:attributeDict atIndex:0]; //if it's the image we want first, insert it at index 0
        } else {
            [self.parsedImgTagAttributeDicts addObject:attributeDict];
        }
    }
}

- (NSString*)imgTagsOnlyFromHTMLString:(NSString*)HTMLString {
    static NSRegularExpression* imgTagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imgTagRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:<img\\s)(?:[^>]*)(?:>)"
                                                                options:NSRegularExpressionCaseInsensitive
                                                                  error:nil];
    });
    NSArray<NSTextCheckingResult*>* matches = [imgTagRegex matchesInString:HTMLString options:0 range:NSMakeRange(0, HTMLString.length)];
    return [[matches bk_map:^id (NSTextCheckingResult* match){
        NSString *imgTag = [HTMLString substringWithRange:match.range];
        
        // Temporarily escape all tag attribute values so NSXMLParser doesn't encounter anything it can't handle.
        imgTag = [imgTag wmf_stringWithPercentEncodedTagAttributeValues];
        
        return imgTag;
    }] componentsJoinedByString:@""];
}

@end

NS_ASSUME_NONNULL_END
