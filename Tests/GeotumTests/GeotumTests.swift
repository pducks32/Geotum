import XCTest
@testable import Geotum

func AssertLatLonDistanceIsWithinRange(_ expected : LatLonCoordinate, _ actual : LatLonCoordinate, within : Measurement<UnitAngle>, file : StaticString = #file, line : UInt = #line) {
    let distanceLatitude = abs(actual.latitude.converted(to: .degrees).value - expected.latitude.converted(to: .degrees).value)
    let distanceLongitude = abs(actual.longitude.converted(to: .degrees).value - expected.longitude.converted(to: .degrees).value)
    let withinValue = abs(within.converted(to: .degrees).value)
    
    let latitudeMessage = formatWithinMessage("LatitudeDelta", expected: expected.latitude, actual: actual.latitude, within: within)
    let longitudeMessage = formatWithinMessage("LongitudeDelta", expected: expected.longitude, actual: actual.longitude, within: within)
    
    XCTAssertLessThanOrEqual(distanceLatitude, withinValue, latitudeMessage, file: file, line: line)
    XCTAssertLessThanOrEqual(distanceLongitude, withinValue, longitudeMessage, file: file, line: line)
}

func AssertUTMDistanceIsWithinRange(_ expected : UTMPoint, _ actual : UTMPoint, within : Measurement<UnitLength>, file : StaticString = #file, line : UInt = #line) {
    let distance = expected - actual
    let withinValue = within.converted(to: .meters).value
    
    let expectedEasting = Measurement<UnitLength>(value: expected.easting, unit: .meters)
    let actualEasting = Measurement<UnitLength>(value: actual.easting, unit: .meters)
    let eastingMessage = formatWithinMessage("EastingDelta", expected: expectedEasting, actual: actualEasting, within: within)
    
    let expectedNorthing = Measurement<UnitLength>(value: expected.northing, unit: .meters)
    let actualNorthing = Measurement<UnitLength>(value: actual.northing, unit: .meters)
    let northingMessage = formatWithinMessage("NorthingDelta", expected: expectedNorthing, actual: actualNorthing, within: within)
    
    XCTAssertLessThanOrEqual(distance.easting.rounded(.toNearestOrAwayFromZero), withinValue, eastingMessage, file: file, line: line)
    XCTAssertLessThanOrEqual(distance.northing.rounded(.toNearestOrAwayFromZero), withinValue, northingMessage, file: file, line: line)
}

func formatWithinMessage<T : Dimension>(_ key : String, expected : Measurement<T>, actual : Measurement<T>, within : Measurement<T>) -> String {
    let delta = actual.converted(to: within.unit).value - expected.converted(to: within.unit).value
    let incorrectDirection = delta.sign
    let withinDelta = abs(delta) - within.value
    
    let deltaMessage : String
    let withinDeltaUnit = Measurement<T>(value: withinDelta, unit: within.unit)
    if incorrectDirection == .minus {
        // Expected too large
        deltaMessage = "+\(withinDeltaUnit)"
    } else {
        // Expected too small
        deltaMessage = "-\(withinDeltaUnit)"
    }
    return "\(key) ≥ \(within): \(expected) is \(deltaMessage) from \(actual)"
}

class GeotumTests: XCTestCase {
    
    var baseLatLonError = Measurement<UnitAngle>(value: 0.5, unit: .degrees)
    var baseUTMError = Measurement<UnitLength>(value: 0.5, unit: .meters)
    
    func conductTestToUTM(coordinatePair : (Double, Double), toUTM utm : (Double, Double, UInt, UTMPoint.Hemisphere), file : StaticString = #file, line : UInt = #line) {
        let latLonCoordinate = LatLonCoordinate(latiudinalDegrees: coordinatePair.0, longitudinalDegrees: coordinatePair.1)
        
        let actualUTMCoordinate = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: latLonCoordinate)
        let expectedUTMCoordinate = UTMPoint(easting: utm.0, northing: utm.1, zone: utm.2, hemisphere: utm.3)
        
        AssertUTMDistanceIsWithinRange(expectedUTMCoordinate, actualUTMCoordinate, within: baseUTMError, file: file, line: line)
    }
    
    func conductTestToLatLon(utm : (Double, Double, UInt, UTMPoint.Hemisphere), toCoordinatePair coordinatePair : (Double, Double), file : StaticString = #file, line : UInt = #line) {
        let expectedLatLonCoordinate = LatLonCoordinate(latiudinalDegrees: coordinatePair.0, longitudinalDegrees: coordinatePair.1)
        let utmCoordinate = UTMPoint(easting: utm.0, northing: utm.1, zone: utm.2, hemisphere: utm.3)
        
        let actualLatLonCoordinate = UTMConverter(datum: .wgs84).coordinateFrom(utm: utmCoordinate)
        
        AssertLatLonDistanceIsWithinRange(expectedLatLonCoordinate, actualLatLonCoordinate, within: baseLatLonError, file: file, line: line)
    }
    
    func conductTestBetween(utm : (Double, Double, UInt, UTMPoint.Hemisphere), coordinatePair : (Double, Double), file : StaticString = #file, line : UInt = #line) {
        conductTestToUTM(coordinatePair: coordinatePair, toUTM: utm, file: file, line: line)
        conductTestToLatLon(utm: utm, toCoordinatePair: coordinatePair, file: file, line: line)
    }
    
    // Test in another hemisphere and zone
    func testConversionInDuran_SouthWestern() {
        conductTestBetween(utm: (629134.4, 9761758.1, 17, .southern), coordinatePair: (-2.154994, -79.838766))
    }
    func testConversionInMontserrado_NorthWestern() {
        conductTestBetween(utm: (350227.206, 713306.6, 29, .northern), coordinatePair: (6.451436, -10.354367))
    }
    func testConversionInSouthTamworth_SouthEastern() {
        conductTestBetween(utm: (300319, 6556202.6, 56, .southern), coordinatePair: (-31.111072, 150.906144))
    }
    func testConversionInOkinawa_SouthEastern() {
        conductTestBetween(utm: (431651.088, 2965673.550, 52, .northern), coordinatePair: (26.810878, 128.312261))
    }
    
    // Test in norway
    func testEdgeOfNorwaysIsIn32() {
        let coordinatePair : (Double, Double) = (61.042865, 4.684059)
        
        let actualZone = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: LatLonCoordinate(latiudinalDegrees: coordinatePair.0, longitudinalDegrees: coordinatePair.1)).zone
        XCTAssertEqual(actualZone, 32)
    }
    
    func testConversionAtEdgeOfNorways() {
        conductTestBetween(utm: (267000.522, 6775245.720, 32, .northern), coordinatePair: (61.042865, 4.68405899))
    }
    
    // Test near equator
    func testConversionSouthOfEquator() {
        conductTestBetween(utm: (239408, 9999994.1, 18, .southern), coordinatePair: (-0.000053, -77.341218))
    }
    // Test near poles
    
    func testLatLonToUTM() {
        let latitude = 37.0837
        let longitude = -121.9981
        let latLonCoordinate = LatLonCoordinate(latiudinalDegrees: latitude, longitudinalDegrees: longitude)
        
        let actualUTMCoordinate = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: latLonCoordinate)
        let expectedUTMCoordinate = UTMPoint(easting: 589048.564, northing: 4104627.041, zone: 10, hemisphere: .northern)
        
        AssertUTMDistanceIsWithinRange(expectedUTMCoordinate, actualUTMCoordinate, within: baseUTMError)
    }
    
    func testUTMToLatLon() {
        let utmCoordinate = UTMPoint(easting: 589048.6, northing: 4104627, zone: 10, hemisphere: .northern)
        
        let expectedCoordinate = LatLonCoordinate(latiudinalDegrees: 37.0837, longitudinalDegrees: -121.9981)
        let actualCoordinate = UTMConverter(datum: .wgs84).coordinateFrom(utm: utmCoordinate)
        AssertLatLonDistanceIsWithinRange(expectedCoordinate, actualCoordinate, within: baseLatLonError)
    }


    static var allTests = [
        ("testLatLonToUTM", testLatLonToUTM),
        ("testUTMToLatLon", testUTMToLatLon)
    ]
}
