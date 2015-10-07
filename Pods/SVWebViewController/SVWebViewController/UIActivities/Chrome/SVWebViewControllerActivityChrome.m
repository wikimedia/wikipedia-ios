//
//  SVWebViewControllerActivityChrome.h
//
//  Created by Sam Vermette on 11 Nov, 2013.
//  Copyright 2013 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "SVWebViewControllerActivityChrome.h"

@implementation SVWebViewControllerActivityChrome

- (NSString *)schemePrefix {
    return @"googlechrome://";
}

- (NSString *)activityTitle {
	return NSLocalizedStringFromTable(@"Open in Chrome", @"SVWebViewController", nil);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:self.schemePrefix]]) {
			return YES;
		}
	}
	return NO;
}

- (void)performActivity {
    NSString *openingURL = [self.URLToOpen.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *activityURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.schemePrefix, openingURL]];
	[[UIApplication sharedApplication] openURL:activityURL];
    
	[self activityDidFinish:YES];
}

@end
