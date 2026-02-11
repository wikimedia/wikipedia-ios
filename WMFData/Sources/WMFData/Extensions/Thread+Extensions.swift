import Foundation

public extension Thread {
    @objc static func filteredStackTrace(forModules moduleNames: [String], prefix: Int) -> String {
        let fullStack = Thread.callStackSymbols
        var filtered: [String] = []
        
        for frame in fullStack {
            
            // Skip frames from this filtering method itself (handles both Obj-C and Swift mangled names)
            if frame.contains("filteredStackTrace") || frame.contains("callerFrame") || frame.contains("ErrorFunnel") {
                continue
            }
            
            for moduleName in moduleNames {
                if frame.contains(moduleName) {
                    filtered.append(frame)
                    break
                }
            }
        }
        
        return filtered.prefix(prefix).joined(separator:" | ")
    }
}
