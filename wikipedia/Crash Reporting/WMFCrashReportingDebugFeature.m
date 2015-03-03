#import "WMFCrashReportingDebugFeature.h"
#import "WikipediaAppUtils.h"
#import "WMFCrashReportingDefines.h"

NSString* const kCrashReportingDebugTableViewCellReuseId = @"CrashReportingDebugTableViewCell";

@implementation WMFCrashReportingDebugFeature

- (BOOL)isEnabled
{
    if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]
         isEqualToString:WMFHockeyAppAlphaHockeyCFBundleIdentifier]) {
        return YES;
    }
#if WMF_CRASH_REPORTING_ENABLED
    return YES;
#else
    
    return NO;
#endif
}

- (id<WMFDebugTableViewDataSource>)debugViewDataSource
{
    return self;
}

- (id<WMFDebugTableViewDelegate>)debugViewDelegate
{
    return self;
}

#pragma mark - WMFDebugTableViewDataSource

- (NSString*)headerTitle
{
    return MWLocalizedString(@"debug-crash-reporting-section-header", nil);
}

- (NSInteger)numberOfRows
{
    return 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kCrashReportingDebugTableViewCellReuseId];
    cell.textLabel.text = MWLocalizedString(@"debug-crash-reporting-crash-button-title", nil);
    cell.textLabel.textColor = [UIColor redColor];
    return cell;
}

#pragma mark - WMFDebugTableViewDelegate

- (void)applyCellConfigurationToTable:(UITableView *)tableView
{
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCrashReportingDebugTableViewCellReuseId];
}

- (void)didSelectRow:(NSUInteger)row
{
    @throw NSInternalInconsistencyException;
}

@end
