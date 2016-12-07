@interface PageHistoryResultCell : UITableViewCell

- (void)setName:(NSString *)name
           date:(NSDate *)date
          delta:(NSNumber *)delta
         isAnon:(BOOL)isAnon
        summary:(NSString *)summary
      separator:(BOOL)separator;

@end
