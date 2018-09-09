//
//  ViewController.swift
//  MusicalCity
//

import UIKit
import MapKit
//import MapKitGoogleStyler
import CoreLocation

let TOTAL_ZONES = 16

let MASTER_ZONE_RADIUS = 160.0
let SUB_ZONE_RADIUS = 60.0
let LOCATION_MARKER_RADIUS = 10.0

let MASTER_ZONE_COLS = 3
let MASTER_ZONE_ROWS = 3
let MASTER_ZONE_BPM = 120

//let LAT_OFFSET = 59.352284
//let LON_OFFSET = 18.065237
let LAT_ADJUST = 0.005
let LON_ADJUST = -0.003

let X_OFFSET = 652.0
let Y_OFFSET = 200.0
let COORD_SCALE = 0.00001

let DEMO_MODE = false

class Zone {
    var id: Int = 0
}

class CircularZone : Zone {
    init(id: Int, center: CLLocation, radius: Double) {
        super.init()
        
        self.id = id
        self.center = center
        self.radius = radius
    }
    
    var center: CLLocation?
    var radius: Double?
}

class PolygonZone : Zone {
    init(id: Int, polygon: MKPolygon) {
        super.init()
        
        self.id = id
        self.polygon = polygon
    }
    
    var polygon: MKPolygon?
}

class MasterZoneMKCircle: MKCircle {}
class SubZoneMKCircle: MKCircle {}
class LocationMarkerMKCircle: MKCircle {}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, CsoundBinding {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let csound = CsoundObj()
    let locationManager = CLLocationManager()
    
    var sineFreq2Ptr: UnsafeMutablePointer<Float>?
    
    var zones: Array<Zone>?
    var locationMarker: MKCircle?;
    var locationCoordinate: CLLocationCoordinate2D?
    var zoneAmplitudePtrs: Array<UnsafeMutablePointer<Float>> = []
    
    // TODO Remove - testing only
    var latOffset: Double?
    var lonOffset: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCsound()
        initLocation()
    }
    
    
    // ----------------------------------------------------------------------------------------------------
    // Csound
    // ----------------------------------------------------------------------------------------------------
    
    func initCsound() {
        self.csound.setMessageCallback(#selector(printMessage(_:)), withListener: self)
        self.csound.addBinding(self)
        self.csound.play(Bundle.main.path(forResource: "MusicalCity", ofType: "csd"))
    }
    
    func setup(_ csoundObj: CsoundObj) {
        for id in 1...TOTAL_ZONES {
            let zoneAmplitudePtr = csoundObj.getInputChannelPtr("nodeAmp" + String(id), channelType: CSOUND_CONTROL_CHANNEL)
            zoneAmplitudePtr!.pointee = Float(0.0)
            zoneAmplitudePtrs.append(zoneAmplitudePtr!)
        }
    }
    
    func updateValuesToCsound() {
        if self.zones != nil {
            if (self.locationCoordinate != nil) {
                let location = CLLocation(latitude: self.locationCoordinate!.latitude, longitude: self.locationCoordinate!.longitude)
                
                for zone in self.zones! {
                    if zone is CircularZone {
                        let circularZone = zone as! CircularZone
                        let distanceMetres = circularZone.center!.distance(from: location)
                        let distanceNormalized = distanceMetres / circularZone.radius!
                        let k = 7.0
                        let x0 = 0.6
                        let amplitude = max(1 / (1 + exp(-k * ((1.0 - distanceNormalized) - x0))), 0.0)
                        
                        zoneAmplitudePtrs[zone.id - 1].pointee = Float(amplitude)
                    } else if zone is PolygonZone {
                        let polygonZone = zone as! PolygonZone
                        let polygonRenderer = MKPolygonRenderer(polygon: polygonZone.polygon!)
                        let mapPoint: MKMapPoint = MKMapPointForCoordinate(self.locationCoordinate!)
                        let polygonViewPoint: CGPoint = polygonRenderer.point(for: mapPoint)
                        
                        if polygonRenderer.path.contains(polygonViewPoint) {
                            zoneAmplitudePtrs[zone.id - 1].pointee = Float(1.0)
                        } else {
                            zoneAmplitudePtrs[zone.id - 1].pointee = Float(0.0)
                        }
                    }
                }
            } else {
                for zone in self.zones! {
                    zoneAmplitudePtrs[zone.id - 1].pointee = Float(0.0)
                }
            }
        }
    }
    
    @objc
    func printMessage(_ infoObj: NSValue) {
        var info = Message()
        infoObj.getValue(&info)
        let message = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
        let va_ptr: CVaListPointer = CVaListPointer(_fromUnsafeMutablePointer: &(info.valist))
        vsnprintf(message, 1024, info.format, va_ptr)
        let messageStr = String(cString: message)
        print("[csound] " + messageStr)
    }
    
    
    // ----------------------------------------------------------------------------------------------------
    // Location and Map
    // ----------------------------------------------------------------------------------------------------
    
    func initLocation() {
        self.mapView.delegate = self
//        self.mapView.mapType = MKMapType.satellite
        
        if (DEMO_MODE) {
            self.mapView.isUserInteractionEnabled = false
            self.mapView.isScrollEnabled = false
            self.mapView.isZoomEnabled = false
        }
        
//        let overlay = MKTileOverlay(urlTemplate: "http://a.tile.stamen.com/toner/${z}/${x}/${y}.png")
//        overlay.canReplaceMapContent = true
//        self.mapView.add(overlay)

//        configureTileOverlay()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            print("Location services not enabled!")
        }
    }
    
//    func configureTileOverlay() {
//        guard let overlayFileURLString = Bundle.main.path(forResource: "MapStyle", ofType: "json") else {
//            return
//        }
//        let overlayFileURL = URL(fileURLWithPath: overlayFileURLString)
//
//        guard let tileOverlay = try? MapKitGoogleStyler.buildOverlay(with: overlayFileURL) else {
//            return
//        }
//
//        // And finally add it to your MKMapView
//        mapView.add(tileOverlay)
//    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let isFirstLocation = self.locationCoordinate == nil
        
        self.locationCoordinate = locations.last!.coordinate
        
        if (!DEMO_MODE || isFirstLocation) {
            let center = CLLocationCoordinate2D(latitude: self.locationCoordinate!.latitude, longitude: self.locationCoordinate!.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.013))
            
            self.mapView.setRegion(region, animated: true)
        }

        if (!DEMO_MODE) {
            updateLocationMarker()
        }
        
        if (zones == nil) {
            self.latOffset = self.locationCoordinate?.latitude;
            self.lonOffset = self.locationCoordinate?.longitude;
            initZones()
        }
    }
    
    func updateLocationMarker() {
        if (self.locationMarker != nil) {
            self.mapView.remove(self.locationMarker!)
        }
        
        self.locationMarker = LocationMarkerMKCircle(
            center: locationCoordinate!,
            radius: LOCATION_MARKER_RADIUS as CLLocationDistance
        )
        self.mapView.add(self.locationMarker!)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MasterZoneMKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor(red: 161.0/255.0, green: 102.0/255.0, blue: 255.0/255.0, alpha: 1.0)
//            circle.strokeColor = UIColor(red: 161.0/255.0, green: 102.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            circle.lineWidth = 2
            return circle
        } else if overlay is SubZoneMKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor(red: 26.0/255.0, green: 255.0/255.0, blue: 217.0/255.0, alpha: 1.0)
//            circle.strokeColor = UIColor(red: 26.0/255.0, green: 255.0/255.0, blue: 217.0/255.0, alpha: 1.0)
            circle.lineWidth = 2
            return circle
        } else if overlay is MKPolygon {
            let circle = MKPolygonRenderer(polygon: (overlay as! MKPolygon))
            circle.strokeColor = UIColor(red: 195.0/255.0, green: 255.0/255.0, blue: 80.0/255.0, alpha: 1.0)
//            circle.strokeColor = UIColor(red: 195.0/255.0, green: 255.0/255.0, blue: 80.0/255.0, alpha: 1.0)
            circle.lineWidth = 2
            return circle
        } else if overlay is LocationMarkerMKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.white
            circle.fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
            circle.lineWidth = 0.6
            return circle
        } else if overlay is MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: overlay as! MKTileOverlay)
        } else {
            return MKPolylineRenderer()
        }
    }
    
    
    // ----------------------------------------------------------------------------------------------------
    // Zones
    // ----------------------------------------------------------------------------------------------------
    
    func initZones() {
        zones = []
        
        addMasterZone(x: 551, y: 323, radius: MASTER_ZONE_RADIUS)
        addMasterZone(x: 852, y: 181, radius: MASTER_ZONE_RADIUS)
        addMasterZone(x: 913, y: 765, radius: MASTER_ZONE_RADIUS)
        
        addSubZone(x: 604, y: 364, radius: SUB_ZONE_RADIUS * 2.0)
        addSubZone(x: 629, y: 398, radius: SUB_ZONE_RADIUS * 0.9)
        addSubZone(x: 711, y: 378, radius: SUB_ZONE_RADIUS * 1.0)
        addSubZone(x: 687, y: 448, radius: SUB_ZONE_RADIUS * 1.0)
        
        addSubZone(x: 925, y: 213, radius: SUB_ZONE_RADIUS * 2.0)
        addSubZone(x: 984, y: 239, radius: SUB_ZONE_RADIUS * 0.9)
        addSubZone(x: 991, y: 296, radius: SUB_ZONE_RADIUS * 1.0)

        addSubZone(x: 979, y: 816, radius: SUB_ZONE_RADIUS * 2.0)
        addSubZone(x: 1002, y: 868, radius: SUB_ZONE_RADIUS * 0.6)
        addSubZone(x: 1043, y: 852, radius: SUB_ZONE_RADIUS * 1.3)
        
        addFreeZone(coordinates: [
            toCoordinate(x: 641, y: 23),
            toCoordinate(x: 864, y: 2),
            toCoordinate(x: 913, y: 183),
            toCoordinate(x: 648, y: 352)
        ])
        
        addFreeZone(coordinates: [
            toCoordinate(x: 848, y: 38),
            toCoordinate(x: 1133, y: 39),
            toCoordinate(x: 1172, y: 134),
            toCoordinate(x: 1254, y: 201),
            toCoordinate(x: 1239, y: 372),
            toCoordinate(x: 1171, y: 292),
            toCoordinate(x: 1067, y: 245),
            toCoordinate(x: 1016, y: 194),
            toCoordinate(x: 930, y: 216),
            toCoordinate(x: 882, y: 178),
            toCoordinate(x: 882, y: 125)
        ])
        
        addFreeZone(coordinates: [
            toCoordinate(x: 870, y: 400),
            toCoordinate(x: 1023, y: 437),
            toCoordinate(x: 1126, y: 440),
            toCoordinate(x: 1150, y: 486),
            toCoordinate(x: 1042, y: 741),
            toCoordinate(x: 1059, y: 851),
            toCoordinate(x: 1039, y: 876),
            toCoordinate(x: 956, y: 817),
            toCoordinate(x: 931, y: 676),
            toCoordinate(x: 839, y: 511)
        ])
    }
    
    func addMasterZone(x: Double, y: Double, radius: Double){
        let lat = toLat(y: -y) - radius * COORD_SCALE
        let lon = toLon(x: x) + radius * COORD_SCALE
        
        self.zones!.append(CircularZone(
            id: self.zones!.count + 1,
            center: CLLocation(latitude: lat, longitude: lon),
            radius: MASTER_ZONE_RADIUS
        ))
        
        self.mapView.add(MasterZoneMKCircle(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            radius: radius as CLLocationDistance
        ))
    }
    
    func addSubZone(x: Double, y: Double, radius: Double){
        let lat = toLat(y: -y) - radius * COORD_SCALE
        let lon = toLon(x: x) + radius * COORD_SCALE
        
        self.zones!.append(CircularZone(
            id: self.zones!.count + 1,
            center: CLLocation(latitude: lat, longitude: lon),
            radius: SUB_ZONE_RADIUS
        ))
        
        self.mapView.add(SubZoneMKCircle(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            radius: radius as CLLocationDistance
        ))
    }
    
    func addFreeZone(coordinates: Array<CLLocationCoordinate2D>){
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        
        self.zones!.append(PolygonZone(
            id: self.zones!.count + 1,
            polygon: polygon
        ))
        
        self.mapView.add(polygon)
    }
    
    func toLat(y: Double) -> Double {
        return self.latOffset! + (y - Y_OFFSET) * COORD_SCALE + LAT_ADJUST;
    }
    
    func toLon(x: Double) -> Double {
        return self.lonOffset! + (x - X_OFFSET) * COORD_SCALE + LON_ADJUST;
    }
    
    func toCoordinate(x: Double, y: Double) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: toLat(y: -y - 50.0), longitude: toLon(x: (x - 290.0) * 1.4))
    }
    
    
    // ----------------------------------------------------------------------------------------------------
    // Input
    // ----------------------------------------------------------------------------------------------------
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLocationFromTouch(touches);
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLocationFromTouch(touches);
    }
    
    func setLocationFromTouch(_ touches: Set<UITouch>) {
        if let touch = touches.first {
            let touchCoordinate = touch.location(in: view);
            
            if  (DEMO_MODE) {
                self.locationCoordinate = self.mapView.convert(touchCoordinate, toCoordinateFrom: self.mapView);
                updateLocationMarker()
            }
        }
    }
    
    
    // ----------------------------------------------------------------------------------------------------
    // System
    // ----------------------------------------------------------------------------------------------------
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

