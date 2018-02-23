#import <WMF/WMFImageTagParser.h>
#import <WMF/WMFImageTag.h>
#import <WMF/WMFImageTagList.h>
#import <WMF/WMFImageURLParsing.h>
#import <WMF/NSString+WMFHTMLParsing.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFImageTagParser ()

@property (nonatomic, strong, nullable) NSString *leadImageNormalizedFilename;

@end

@implementation WMFImageTagParser

- (WMFImageTagList *)imageTagListFromParsingHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL leadImageURL:(nullable NSURL *)leadImageURL {
    HTMLString = [HTMLString copy];

    self.leadImageNormalizedFilename = WMFParseUnescapedNormalizedImageNameFromSourceURL(leadImageURL.absoluteString);

    NSMutableArray<WMFImageTag *> *imageTags = [NSMutableArray arrayWithCapacity:10];
    [HTMLString wmf_enumerateHTMLImageTagContentsWithHandler:^(NSString *imageTagContents, NSRange range) {
        WMFImageTag *tag = [[WMFImageTag alloc] initWithImageTagContents:imageTagContents baseURL:baseURL];
        if (tag != nil) {
            if (self.leadImageNormalizedFilename && [WMFParseUnescapedNormalizedImageNameFromSourceURL(tag.src) isEqualToString:self.leadImageNormalizedFilename]) { //check if this is the image we want first in the list by comparing filenames
                [imageTags insertObject:tag atIndex:0];                                                                                                              //if it's the image we want first, insert it at index 0
            } else {
                [imageTags addObject:tag];
            }
        }
    }];

    return [[WMFImageTagList alloc] initWithImageTags:imageTags];
}

- (WMFImageTagList *)imageTagListFromParsingHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL {
    return [self imageTagListFromParsingHTMLString:HTMLString withBaseURL:baseURL leadImageURL:nil];
}

@end

NS_ASSUME_NONNULL_END
