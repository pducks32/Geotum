//
//  main.swift
//  Geotum Command Line
//
//  Created by Patrick Metcalfe on 11/19/18.
//

import Foundation
import Basic
import Utility
import Geotum

enum SupportedSystem: String, StringEnumArgument {
    static var completion: ShellCompletion = .values([
        (value: "utm", description: "Universal Transverse Mercator Projection"),
        (value: "latlon", description: "Standard Latitude Longitude (in that order)")])
    
    case utm
    case latlon
    
    static func inferredTo(whenFrom: SupportedSystem) -> SupportedSystem {
        return inferredFrom(whenTo: whenFrom)
    }
    
    static func inferredFrom(whenTo: SupportedSystem) -> SupportedSystem {
        switch whenTo {
        case .utm: return .latlon
        case .latlon: return .utm
        }
    }
}

enum KeyStyle {
    case abbreviated
    case long
}

enum FormatStyle {
    /// JSON formmated coordinates with `KeyStyle` keys
    case json(keys: KeyStyle)
    
    /// Key (Latitude, Longitude, etc) styled as `KeyStyle`
    /// or ommited (`nil`) then a space then delimator
    /// then repeat for each coordinate point
    case keyValue(keys: KeyStyle?, deliminator: String)
}

class UTMCoordinateFormatter : Formatter {
    
}

let negativeProxy = "–" // Em Dash
let isNegativeAndNotPositional = try! NSRegularExpression(pattern: "(-)(\\d|\\.)", options: [])

let parser = ArgumentParser(commandName: "geotum", usage: "41.943423, -87.666169", overview: "Convert to and from utm")

let coordinatesArgument = parser.add(positional: "Coordinate", kind: [String].self, optional: false, strategy: .upToNextOption, usage: "41.943423, -87.666169", completion: .none)
let fromArgument = parser.add(option: "--from", shortName: nil, kind: SupportedSystem.self, usage: "--from=utm")
let toArgument = parser.add(option: "--to", shortName: nil, kind: SupportedSystem.self, usage: "--to=utm")


let args = ProcessInfo.processInfo.arguments.dropFirst().map({ arg -> String in
    let matches = isNegativeAndNotPositional.matches(in: arg, options: [], range: NSRange(location: 0, length: arg.count))
    guard !matches.isEmpty else { return arg }
    return arg.replacingOccurrences(of: "-", with: negativeProxy)
})


let arguments = try! parser.parse(Array(args))
let coordinateParts = arguments.get(coordinatesArgument)!.map({ part -> Double in
    let cleanedPart = part.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: negativeProxy, with: "-")
    return Double(cleanedPart)!
})
let latLonCoordinate = LatLonCoordinate(latiudinalDegrees: coordinateParts[0], longitudinalDegrees: coordinateParts[1])
let utm = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: latLonCoordinate)
print("\(utm.easting)E \(utm.northing)N \(utm.zone)\(utm.hemisphere.abbreviation)")


