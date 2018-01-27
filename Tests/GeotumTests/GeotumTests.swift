import XCTest
@testable import Geotum

func AssertLatLonDistanceIsWithinRange(_ expected : LatLonCoordinate, _ actual : LatLonCoordinate, within : Measurement<UnitAngle>, file : StaticString = #file, line : UInt = #line) {
    let distanceLatitude = actual.latitude.converted(to: .degrees).value - expected.latitude.converted(to: .degrees).value
    let distanceLongitude = actual.longitude.converted(to: .degrees).value - expected.longitude.converted(to: .degrees).value
    let withinValue = within.converted(to: .degrees).value
    XCTAssertLessThanOrEqual(distanceLatitude, withinValue, file: file, line: line)
    XCTAssertLessThanOrEqual(distanceLongitude, withinValue, file: file, line: line)
}
func AssertUTMDistanceIsWithinRange(_ expected : UTMPoint, _ actual : UTMPoint, within : Measurement<UnitLength>, file : StaticString = #file, line : UInt = #line) {
    let distance = expected - actual
    let withinValue = within.converted(to: .meters).value
    XCTAssertLessThanOrEqual(distance.easting.rounded(.toNearestOrAwayFromZero), withinValue, file: file, line: line)
    XCTAssertLessThanOrEqual(distance.northing.rounded(.toNearestOrAwayFromZero), withinValue, file: file, line: line)
}

class GeotumTests: XCTestCase {
    
    var baseLatLonError = Measurement<UnitAngle>(value: 1, unit: .degrees)
    var baseUTMError = Measurement<UnitLength>(value: 1, unit: .meters)
    
    func conductTestBetween(coordinatePair : (Double, Double), utm : (Double, Double, UInt, UTMPoint.Hemisphere), file : StaticString = #file, line : UInt = #line) {
        let latLonCoordinate = LatLonCoordinate(latiudinalDegrees: coordinatePair.0, longitudinalDegrees: coordinatePair.1)
        
        let actualUTMCoordinate = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: latLonCoordinate)
        let expectedUTMCoordinate = UTMPoint(easting: utm.0, northing: utm.1, zone: utm.2, hemisphere: utm.3)
        
        AssertUTMDistanceIsWithinRange(expectedUTMCoordinate, actualUTMCoordinate, within: baseUTMError, file: file, line: line)
    }
    
    // Test in another hemisphere and zone
    func testLatLonToUTMInDuran_SouthWestern() {
        conductTestBetween(coordinatePair: (-2.154994, -79.838766), utm: (629134.4, 9761758.1, 17, .southern))
    }
    func testLatLonToUTMInMontserrado_NorthWestern() {
        conductTestBetween(coordinatePair: (6.451436, -10.354367), utm: (350227.2, 713306.6, 29, .northern))
    }
    func testLatLonToUTMInSouthTamworth_SouthEastern() {
        conductTestBetween(coordinatePair: (-31.111072, 150.906144), utm: (300319, 6556202.6, 56, .southern))
    }
    func testLatLonToUTMInOkinawa_SouthEastern() {
        conductTestBetween(coordinatePair: (26.810878, 128.312261), utm: (431651.1, 2965673.6, 52, .northern))
    }
    
    // Test in norway
    // Test near equator
    // Test near poles
    // Reversability
    
    func testLatLonToUTM() {
        let latitude = 37.0837
        let longitude = -121.9981
        let latLonCoordinate = LatLonCoordinate(latiudinalDegrees: latitude, longitudinalDegrees: longitude)
        
        let actualUTMCoordinate = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: latLonCoordinate)
        let expectedUTMCoordinate = UTMPoint(easting: 589048.6, northing: 4104627, zone: 10, hemisphere: .northern)
        
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
