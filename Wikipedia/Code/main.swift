import Foundation

let workarounder = SwiftKVOCrashWorkaround()
workarounder.performWorkaround()

var delegateClass = NSStringFromClass(AppDelegate.self)

#if TEST
if (NSClassFromString("XCTestCase") != nil) {
    delegateClass = NSStringFromClass(MockAppDelegate.self)
}
#endif

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClass)
