SSDataSources
=============

[![Circle CI](https://circleci.com/gh/splinesoft/SSDataSources.svg?style=svg&circle-token=cdbc822ee90ca92ed398f8a3277389474ef613f2)](https://circleci.com/gh/splinesoft/SSDataSources) [![Documentation](http://img.shields.io/cocoapods/v/SSDataSources.svg?style=flat)](http://cocoadocs.org/docsets/SSDataSources/) [![Coverage Status](https://coveralls.io/repos/splinesoft/SSDataSources/badge.svg)](https://coveralls.io/r/splinesoft/SSDataSources)

Flexible data sources for your `UITableView` and `UICollectionView`. *wow, much DRY*

No doubt you've done the `tableView:cellForRowAtIndexPath:` and `tableView:numberOfRowsInSection:` and `collectionView:cellForItemAtIndexPath:` and `collectionView:numberOfItemsInSection:` dances many times before. You may also have updated your data and forgotten to update the table or collection view. Whoops -- crash! Is there a better way?

`SSDataSources` is a collection of objects that conform to `UITableViewDataSource` and `UICollectionViewDataSource`. An abstract superclass, `SSBaseDataSource`, defines a common interface that is implemented by four concrete subclasses:

- `SSArrayDataSource` powers a table or collection view with a single section.
- `SSSectionedDataSource` powers a table or collection view with multiple sections.
- `SSCoreDataSource` powers a table or collection view backed by a Core Data fetch request.
- `SSExpandingDataSource` powers a table or collection view with multiple sections, much like `SSSectionedDataSource`, but also allows for sections to be expanded and collapsed.

`SSDataSources` is my own implementation of ideas featured in [objc.io's wonderful first issue](http://www.objc.io/issue-1/table-views.html).

`SSDataSources` powers single-section, multi-section, and Core Data-backed tables in my app [MUDRammer - A Modern MUD client for iPhone and iPad](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8).

## Install

Install with [CocoaPods](http://cocoapods.org). Add to your `Podfile`:

```
pod 'SSDataSources', :head # YOLO
```

## Example

All the tables and collection views in the `Example` project are built with `SSDataSources`.

```bash
pod try SSDataSources
```

Or:

```bash
cd Example
pod install
open ExampleSSDataSources.xcworkspace
```

## Array Data Source

`SSArrayDataSource` powers a table or collection view with a single section. See `SSArrayDataSource.h` for more details.

Check out the example project for sample table and collection views that use the array data source.

`SSArrayDataSource` can also observe a target and key path for array content. 


```objc
@interface WizardicTableViewController : UITableViewController

@property (nonatomic, strong) SSArrayDataSource *wizardDataSource;

@end

@implementation WizardicTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _wizardDataSource = [[SSArrayDataSource alloc] initWithItems:
                         @[ @"Merlyn", @"Gandalf", @"Melisandre" ]];

    // SSDataSources creates your cell and calls
    // this configure block for each cell with 
    // the object being presented in that cell,
    // the parent table or collection view,
    // and the index path at which the cell appears.
    self.wizardDataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, 
                                                 NSString *wizard,
                                                 UITableView *tableView,
                                                 NSIndexPath *indexPath) {
        cell.textLabel.text = wizard;
    };
    
    self.wizardDataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                                   UITableView *tableView,
                                                   NSIndexPath *indexPath) {
        // Disallow gestures for moving and editing.
        // You could instead do something like allowing only editing:
        // return action == SSCellActionTypeEdit;
        return NO;
    };
    
    // Set the tableView property and the data source will perform
    // insert/reload/delete calls on the table as its data changes.
    // This also assigns the table's `dataSource` property.
    self.wizardDataSource.tableView = self.tableView;
}
@end
```

That's it - you're done! 

Perhaps your data changes:

```objc
// Sometimes it's nice to add a view that automatically 
// shows when the data source is empty and
// hides when the data source has items.
UILabel *noItemsLabel = [UILabel new];
noItemsLabel.text = @"No Items";
noItemsLabel.font = [UIFont boldSystemFontOfSize:18.0f];
noItemsLabel.textAlignment = NSTextAlignmentCenter;
self.wizardDataSource.emptyView = noItemsLabel;

// Optional - row animation for table updates.
self.wizardDataSource.rowAnimation = UITableViewRowAnimationFade;
    
// Automatically inserts two new cells at the end of the table.
[self.wizardDataSource appendItems:@[ @"Saruman", @"Alatar" ]];

// Update the fourth item; reloads the fourth row.
[self.wizardDataSource replaceItemAtIndex:3 withItem:@"Pallando"];

// Sorry Merlyn :(
[self.wizardDataSource moveItemAtIndex:0 toIndex:1];
    
// Remove the second and third cells.
[self.wizardDataSource removeItemsInRange:NSMakeRange( 1, 2 )];
```

Perhaps you have custom table cell classes or multiple classes in the same table:

```objc
self.wizardDataSource.cellCreationBlock = ^id(NSString *wizard, 
                                              UITableView *tableView, 
                                              NSIndexPath *indexPath) {
    if ([wizard isEqualToString:@"Gandalf"]) {
        return [MiddleEarthWizardCell cellForTableView:tableView];
    } else if ([wizard isEqualToString:@"Merlyn"]) {
        return [ArthurianWizardCell cellForTableView:tableView];
    }
};

```

Your view controller should continue to implement `UITableViewDelegate`. `SSDataSources` can help there too:

```objc
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *wizard = [self.wizardDataSource itemAtIndexPath:indexPath];
    
    // do something with `wizard`
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *wizard = [self.wizardDataSource itemAtIndexPath:indexPath];

    // Calculate and return a height for `wizard`.
    // You might do something like...
    return [wizard boundingRectWithSize:CGSizeMake(CGRectGetWidth(tv), CGFLOAT_MAX)
                                options:NSStringDrawingUsesLineFragmentOrigin
                             attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14] }
                                context:NULL].height;
}
```

## Sectioned Data Source

`SSSectionedDataSource` powers a table or collection view with multiple sections. Each section is modeled with an `SSSection` object, which stores the section's items and a few other configurable bits. See `SSSectionedDataSource.h` and `SSSection.h` for more details.

Check out the example project for a sample table that uses the sectioned data source.

```objc
@interface ElementalTableViewController : UITableViewController

@property (nonatomic, strong) SSSectionedDataSource *elementDataSource;

@end

@implementation ElementalTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Let's start with one section
    _elementDataSource = [[SSSectionedDataSource alloc] initWithItems:@[ @"Earth" ]];

    self.elementDataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, 
                                                  NSString *element,
                                                  UITableView *tableView,
                                                  NSIndexPath *indexPath) {
         cell.textLabel.text = element;
    };
    
    // Setting the tableView property automatically updates 
    // the table in response to data changes.
    // This also sets the table's `dataSource` property.
    self.elementDataSource.tableView = self.tableView;
}
@end
```

`SSSectionedDataSource` has you covered if your data changes:
 
```objc
// Sometimes it's nice to add a view that automatically 
// shows when the data source is empty and
// hides when the data source has items.
UILabel *noItemsLabel = [UILabel new];
noItemsLabel.text = @"No Items";
noItemsLabel.font = [UIFont boldSystemFontOfSize:18.0f];
noItemsLabel.textAlignment = NSTextAlignmentCenter;
self.elementDataSource.emptyView = noItemsLabel;
    
// Animation for table updates
self.elementDataSource.rowAnimation = UITableViewRowAnimationFade;

// Add some new sections
[self.elementDataSource appendSection:[SSSection sectionWithItems:@[ @"Fire" ]]];
[self.elementDataSource appendSection:[SSSection sectionWithItems:@[ @"Wind" ]]];
[self.elementDataSource appendSection:[SSSection sectionWithItems:@[ @"Water" ]]];
[self.elementDataSource appendSection:[SSSection sectionWithItems:@[ @"Heart", @"GOOOO PLANET!" ]]];

// Are you 4 srs, heart?
[self.elementDataSource removeSectionAtIndex:([elementDataSource numberOfSections] - 1)];
```

## Expanding Data Source

`SSExpandingDataSource` powers a table or collection view with multiple sections, much like `SSSectionedDataSource`, but also allows for sections to be expanded and collapsed. 

Any number of sections may be toggled open or closed. Different sections can display different numbers of rows when they are collapsed.

Check out the example project for a sample table using the expanding data source.

```objc
@interface ExpandingTableViewController : UITableViewController

@property (nonatomic, strong) SSExpandingDataSource *dataSource;

@end

@implementation ExpandingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _dataSource = [[SSExpandingDataSource alloc] initWithItems:@[ @1, @2, @3 ]];
    [self.dataSource appendSection:[SSSection sectionWithItems:@[ @4, @5, @6 ]]];

    self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, 
                                           NSNumber *number,
                                           UITableView *tableView,
                                           NSIndexPath *indexPath) {
         cell.textLabel.text = [number stringValue];
    };
    
    self.dataSource.collapsedSectionCountBlock = ^NSInteger(SSSection *section,
                                                            NSInteger sectionIndex) {
         // Each section can show different numbers of rows when collapsed.
         // Here, sections collapse down to 1 row more than their index in the table.
         // Section 0 collapses to 1 row, section 1 collapses to 2 rows...
         return 1 + sectionIndex;
    };
    
    // Setting the tableView property automatically updates 
    // the table in response to data changes.
    // This also sets the table's `dataSource` property.
    self.dataSource.tableView = self.tableView;
    
    // Collapse the second section.
    // You could also do this in response to a touch or any other event.
    [self.dataSource setSectionAtIndex:1 expanded:NO];
}
@end
```

## Core Data

You're a modern wo/man-about-Internet and sometimes you want to present a `UITableView` or `UICollectionView` backed by a core data fetch request or fetched results controller. `SSDataSources` has you covered with `SSCoreDataSource`, featured here with a cameo by [MagicalRecord](https://github.com/magicalpanda/MagicalRecord).

```objc
@interface SSCoreDataTableViewController : UITableViewController

@property (nonatomic, strong) SSCoreDataSource *dataSource;

@end

@implementation SSCoreDataTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSFetchRequest *triggerFetch = [Trigger MR_requestAllSortedBy:[Trigger defaultSortField]
                                                        ascending:[Trigger defaultSortAscending]];
   
    _dataSource = [[SSCoreDataSource alloc] initWithFetchRequest:triggerFetch
                                                       inContext:[NSManagedObjectContext 
                                                                  MR_defaultContext]
                                              sectionNameKeyPath:nil];
                                                 
    self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell, 
                                           Trigger *trigger, 
                                           UITableView *tableView,
                                           NSIndexPath *indexPath ) {
         cell.textLabel.text = trigger.name;
    };
    
    // SSCoreDataSource conforms to NSFetchedResultsControllerDelegate.
    // Set the `tableView` property to automatically update the table 
    // after changes in the data source's managed object context.
    // This also sets the tableview's `dataSource`.
    self.dataSource.tableView = self.tableView;
    
    // Optional - row animation to use for update events.
    self.dataSource.rowAnimation = UITableViewRowAnimationFade;
    
    // Optional - permissions for editing and moving
    self.dataSource.tableActionBlock = ^BOOL(SSCellActionType actionType,
                                             UITableView *tableView,
                                             NSIndexPath *indexPath) {
         
         // Disallow moving, allow editing
         return actionType == SSCellActionTypeEdit;
    };
    
    // Optional - handle managed object deletion
    self.dataSource.tableDeletionBlock = ^(SSCoreDataSource *aDataSource,
                                           UITableView *tableView,
                                           NSIndexPath *indexPath) {
                                      
        Trigger *myObject = [aDataSource itemAtIndexPath:indexPath];
        
        // SSCoreDataSource conforms to NSFetchedResultsControllerDelegate,
        // so saving the object's context will automatically update the table.
        [myObject deleteInContext:myObject.managedObjectContext];
        [myObject.managedObjectContext MR_saveToPersistentStoreWithCompletion:nil];
    };
}
@end
```

## Thanks!

`SSDataSources` is a [@jhersh](https://github.com/jhersh) production -- ([electronic mail](mailto:jon@her.sh) | [@jhersh](https://twitter.com/jhersh))
