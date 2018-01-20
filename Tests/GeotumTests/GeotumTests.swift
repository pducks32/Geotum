import XCTest
@testable import Geotum

class GeotumTests: XCTestCase {
    
    func testLatLonToUTM() {
        let latitude = 37.0837
        let longitude = -121.9981
        let latLonCoordinate = LatLonCoordinate(latiudinalDegrees: latitude, longitudinalDegrees: longitude)
        let actualUTMCoordinate = UTMConverter(datum: .wgs84).utmCoordinatesFrom(coordinates: latLonCoordinate)
        let expectedUTMCoordinate = UTMPoint(easting: 589048.6, northing: 4104627, zone: 10, hemisphere: .northern)
        
        let distance = expectedUTMCoordinate - actualUTMCoordinate
        
        XCTAssertLessThanOrEqual(distance.easting.rounded(.toNearestOrAwayFromZero), 1)
        XCTAssertLessThanOrEqual(distance.northing.rounded(.toNearestOrAwayFromZero), 1)
    }
    
    func testUTMToLatLon() {
        let latitude = 37.0837
        let longitude = -121.9981
        let utmCoordinate = UTMPoint(easting: 589048.6, northing: 4104627, zone: 10, hemisphere: .northern)
        let expectedCoordinate = LatLonCoordinate(latiudinalDegrees: latitude, longitudinalDegrees: longitude)
        let actualCoordinate = UTMConverter(datum: .wgs84).coordinateFrom(utm: utmCoordinate)
        
        
        let distanceLatitude = actualCoordinate.latitude.converted(to: .degrees).value - expectedCoordinate.latitude.converted(to: .degrees).value
        let distanceLongitude = actualCoordinate.longitude.converted(to: .degrees).value - expectedCoordinate.longitude.converted(to: .degrees).value
        
        XCTAssertLessThanOrEqual(distanceLatitude, 1)
        XCTAssertLessThanOrEqual(distanceLongitude, 1)
    }


    static var allTests = [
        ("testLatLonToUTM", testLatLonToUTM)
    ]
}
