This library encapsulates the new (November 2014) data model
and storage for the Wikipedia iOS app.

We've switched from sticking everything in CoreData blobs to
using the filesystem.

This has some pluses:
* simplifies some access/threading issues, stay on one thread!
* potentially easier to inspect the system
* batch-removal of pages and their cache dependencies is a single directory remove
* using same data storage model for API decoding (JSON) and storage (plist) in many cases

And some minuses:
* can't do arbitrary SQL-style queries!
* don't benefit from automatic compression etc

It's split out as a subproject to make it easy to unit-test.
