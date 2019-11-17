import AppKit

func toJson<T>(_ data: T) throws -> String {
	let json = try JSONSerialization.data(withJSONObject: data)
	return String(data: json, encoding: .utf8)!
}

func trackApp(){
    let frontmostAppPID = NSWorkspace.shared.frontmostApplication!.processIdentifier
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]

    for window in windows {
        let windowOwnerPID = window[kCGWindowOwnerPID as String] as! Int

        if windowOwnerPID != frontmostAppPID {
            continue
        }
    
        if (window[kCGWindowAlpha as String] as! Double) == 0 {
            continue
        }

        let bounds = CGRect(dictionaryRepresentation: window[kCGWindowBounds as String] as! CFDictionary)!

        let minWinSize: CGFloat = 50
        if bounds.width < minWinSize || bounds.height < minWinSize {
            continue
        }

        let appPid = window[kCGWindowOwnerPID as String] as! pid_t

        let app = NSRunningApplication(processIdentifier: appPid)!

        let dict: [String: Any] = [
            "title": window[kCGWindowName as String] as? String ?? "",
            "id": window[kCGWindowNumber as String] as! Int,
            "bounds": [
                "x": bounds.origin.x,
                "y": bounds.origin.y,
                "width": bounds.width,
                "height": bounds.height
            ],
            "owner": [
                "name": window[kCGWindowOwnerName as String] as! String,
                "processId": appPid,
                "bundleId": app.bundleIdentifier!,
                "path": app.bundleURL!.path
            ],
            "memoryUsage": window[kCGWindowMemoryUsage as String] as! Int
        ]

        print(try! toJson(dict))
    }
}

func trackApps(){
    trackApp()
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { 
        trackApps()
    }
}
