import Foundation
import CoreLocation
import Geotum
import Basic
import SPMUtility

class LocationProvider : NSObject, CLLocationManagerDelegate {
    static var workQueue = DispatchQueue(label: "rocks.metcalfe.location-provider")
    static let manager = CLLocationManager()
    var completionHandler : (Swift.Result<CLLocation, Error>) -> Void
    init(completionHandler : @escaping (Swift.Result<CLLocation, Error>) -> Void) {
        self.completionHandler = completionHandler
        super.init()
        LocationProvider.manager.delegate = self
        LocationProvider.manager.desiredAccuracy = kCLLocationAccuracyBest
        LocationProvider.manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let first = locations.first else { return }
        defer { LocationProvider.manager.stopUpdatingLocation() }
        completionHandler(.success(first))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        print(CLLocationManager.authorizationStatus().rawValue)
        completionHandler(.failure(error))
    }
}

extension ArgumentKind where Self: RawRepresentable, Self.RawValue == String, Self: CaseIterable, Self: CustomStringConvertible {
    static var completion: ShellCompletion {
        return ShellCompletion.values(Self.allCases.map { ($0.rawValue, $0.description)})
    }
    
    init(argument: String) throws {
        guard let properSelf = Self.init(rawValue: argument) else {
            throw NSError(domain: "hi", code: 1, userInfo: nil)
        }
        
        self = properSelf
    }
}

enum ConversionProduct: String, CaseIterable, ArgumentKind, CustomStringConvertible {
    case utm = "UTM"
    case wgs84 = "WGS84"
    
    var description: String {
        switch self {
        case .utm: return "Convert to UTM"
        case .wgs84: return "Convert to Latitude/Longitude"
        }
    }
}

enum OutputFormat: String, CaseIterable, ArgumentKind, CustomStringConvertible {
    case json = "json"
    case standard = "standard"
    case keyValue = "key-value"
    
    var description: String {
        switch self {
        case .json: return "Print as JSON"
        case .standard: return "Print in proper notation"
        case .keyValue: return "Print as new line key value"
        }
    }
}

let parser = ArgumentParser(commandName: "geotum", usage: "<command><parameters>", overview: "Convert and get coordinates")
let format = parser.add(option: "--format", shortName: "f", kind: OutputFormat.self, usage: "-f [format]", completion: OutputFormat.completion)
let output = parser.add(option: "--to", shortName: "to", kind: ConversionProduct.self, usage: "--to [output]", completion: ConversionProduct.completion)
let completionTool = parser.add(subparser: "completion-tool", overview: "Generates Shell completion tool on stdout")
let results = try parser.parse(Array(CommandLine.arguments.dropFirst()))

if case .some("completion-tool") = results.subparser(parser) {
    stdoutStream <<< "#!/bin/bash\n"
    parser.generateCompletionScript(for: .bash, on: stdoutStream)
    stdoutStream <<< "\n\ncomplete -F _geotum geotum\n"
    stdoutStream.flush()
    exit(0)
}

let shouldConvertToUTM = results.get(output) == .some(.utm)

let currentRunLoop = RunLoop.current
var shouldKeepRunning = true
let hia = LocationProvider() { result in
    let string = try? result.map { location -> String in
        let coordinate = LatLonCoordinate(latiudinalDegrees: location.coordinate.latitude, longitudinalDegrees: location.coordinate.longitude)
        if shouldConvertToUTM {
            let point = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: coordinate)
            return "E\(point.easting) N\(point.northing) \(point.zone)\(point.hemisphere.abbreviation)"
        } else {
            return "E\(coordinate.latitude) N\(coordinate.longitude)"
        }
    }.get()
    print(string ?? "None")
    shouldKeepRunning = false
}

while shouldKeepRunning == true && currentRunLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001)) {}
