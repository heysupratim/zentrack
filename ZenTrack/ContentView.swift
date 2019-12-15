//
//  ContentView.swift
//  ZenTrack
//
//  Created by Supratim on 2019-11-12.
//  Copyright © 2019 Supratim Chakraborty. All rights reserved.
//

import SwiftUI

class App: NSObject, Identifiable, NSCoding{
    let id: UUID
    let name: String
    var duration: Double
    var path: String
    
    init(name: String, duration: Double, path: String){
        self.id = UUID()
        self.name=name
        self.duration=duration
        self.path=path
    }
    
    static func ==(lhs: App, rhs: App) -> Bool {
        return lhs.name == rhs.name
    }
    
    required init(coder decoder: NSCoder){
        self.id = decoder.decodeObject(forKey: "id") as! UUID
        self.name = decoder.decodeObject(forKey: "name") as! String
        self.duration = decoder.decodeDouble(forKey: "duration")
        self.path = decoder.decodeObject(forKey: "path") as! String
    }
    
    func encode(with coder: NSCoder){
        coder.encode(id, forKey: "id")
        coder.encode(name, forKey: "name")
        coder.encode(duration, forKey: "duration")
        coder.encode(path, forKey: "path")
    }

}

//extension UserDefaults {
//    func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
//        guard let data = self.value(forKey: key) as? Data else { return nil }
//        return try? decoder.decode(type.self, from: data)
//    }
//
//    func set<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
//        let data = try? encoder.encode(object)
//        self.set(data, forKey: key)
//    }
//}

func dataForDict(dict: [String: App]) throws -> Data {
    return try NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: false)
}

func imageForPath(path: String) -> NSImage{
    return NSWorkspace.shared.icon(forFile: path)
}

func stringFormatted(time: Double)  -> String {
    //let miliseconds = time.truncatingRemainder(dividingBy: 10)
    let interval = Int(time)
    //let seconds = interval % 60
    let minutes = (interval / 60) % 60
    return String(format: "%02d min", minutes)
}

func deleteUserData(){
    UserDefaults.standard.removeObject(forKey: getTodaysDate())
    UserDefaults.standard.synchronize()
}

func exportData(appsTrackDict: [String: App]){
    let fileName = getTodaysDate()+"app_usage.csv"
    var csvText = "App,Duration\n"
    for (_, value) in appsTrackDict {
        let newLine = "\(value.name),\(stringFormatted(time:value.duration))\n"
        csvText.append(newLine)
    }
    let savePanel = NSSavePanel()
    savePanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    savePanel.message = "Save the file"
    savePanel.nameFieldStringValue = fileName
    savePanel.showsHiddenFiles = false
    savePanel.showsTagField = false
    savePanel.canCreateDirectories = true
    savePanel.allowsOtherFileTypes = true
    savePanel.isExtensionHidden = true
    
    if savePanel.runModal() == NSApplication.ModalResponse.OK, let url = savePanel.url {
        do {
            try csvText.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct BlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.blue : Color.white)
            .background(configuration.isPressed ? Color.white : Color.blue)
            .cornerRadius(10.0)
    }
}

struct ContentView: View {
    
    @ObservedObject var fetcher = AppFetcher()
    
    var body: some View {
        VStack{
            Button(action: {exportData(appsTrackDict: self.fetcher.appTrackDict)}) {
            Text("Export Data")
                .padding()
            }
            .padding(.top)
            .buttonStyle(BlueButtonStyle())
            List(fetcher.apps) { app in
                HStack {
                    Image(nsImage:imageForPath(path: app.path))
                        .padding(.leading)
                    Text(app.name)
                        .font(.title)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .padding(.leading)
                        .frame(alignment: .leading)
                    Text(stringFormatted(time: app.duration))
                        .font(.title)
                        .fontWeight(.light)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Date {
    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

func getTodaysDate() -> String {
    return Date().string(format: "yyyy_MM_dd")
}

public class AppFetcher: ObservableObject {

    @Published var apps = [App]()
    
    @Published var appTrackDict: [String: App] = [:]
    
    init(){
//        deleteUserData()
        if let data = UserDefaults.standard.object(forKey: getTodaysDate()) {
            appTrackDict = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data as! Data) as! [String : App]
            apps = Array(appTrackDict.values)
        }
        trackApp()
    }
    
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

            let app = NSRunningApplication(processIdentifier: appPid) ?? nil

            if((app) != nil){
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
                        "bundleId": app?.bundleIdentifier ?? "empty",
                        "path": app?.bundleURL!.path ?? "empty"
                    ],
                    "memoryUsage": window[kCGWindowMemoryUsage as String] as! Int
                ]
                
                let rest = dict["owner"] as? NSDictionary
                let ownerName = rest?.value(forKey: "name") as! String
                let path = app?.bundleURL!.path ?? "empty"
                
                if let val = appTrackDict[ownerName] {
                    let indexOfA = apps.firstIndex(of: val)
                    let timeInterval = val.duration + 2
                    let trackedApp = App(name: ownerName, duration: timeInterval, path:path)
                    appTrackDict[ownerName] = trackedApp
                    apps.remove(at: indexOfA!)
                    apps.insert(trackedApp, at: indexOfA!)
                }else{
                    let begin = Date()
                    let end = Date()
                    let timeInterval = end.timeIntervalSince(begin)
                    let trackedApp = App(name: ownerName, duration: timeInterval, path: path)
                    appTrackDict[ownerName] = trackedApp
                    apps.append(trackedApp)
                }
            }
            let data = try? dataForDict(dict: appTrackDict)
            UserDefaults.standard.set(data, forKey: getTodaysDate())
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.trackApp()
        }
    }
}
