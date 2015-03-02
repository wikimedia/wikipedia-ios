#import "WMFImageURLParsing.h"

NSString* WMFParseImageNameFromSourceURL(NSURL* sourceURL)  __attribute__((overloadable))
{
    return WMFParseImageNameFromSourceURL(sourceURL.absoluteString);
}

NSString* WMFParseImageNameFromSourceURL(NSString* sourceURL)  __attribute__((overloadable))
{
    if (!sourceURL) { return nil; }
    NSString *fileName = [sourceURL lastPathComponent];
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"^\\d+px-(.*)$" options:0 error:nil];
    NSArray *matches = [re matchesInString:fileName options:0 range:NSMakeRange(0, [fileName length])];
    return matches.count ? [fileName substringWithRange:[matches[0] rangeAtIndex:1]] : fileName;
}