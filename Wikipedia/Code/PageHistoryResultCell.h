@class PageHistoryLabel;

@interface PageHistoryResultCell : UITableViewCell

- (void)setName:(NSString *)name
           date:(NSDate *)date
          delta:(NSNumber *)delta
           icon:(NSString *)icon
        summary:(NSString *)summary
      separator:(BOOL)separator;

@end
