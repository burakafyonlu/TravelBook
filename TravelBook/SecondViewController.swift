//
//  SecondViewController.swift
//  TravelBook
//
//  Created by Burak Afyonlu on 21.01.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class SecondViewController: UIViewController , MKMapViewDelegate , CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var chosenLongitude = Double()
    var chosenLatitude = Double()
    var selectedTitle = ""
    var selectedTitleId : UUID?
    var annatationTitle = ""
    var annatationSubtitle = ""
    var annatationLatitude = Double()
    var annatationLongitude = Double()
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mkMapView: MKMapView!
    @IBOutlet weak var saveClicked: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mkMapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation))
        gestureRecognizer.minimumPressDuration = 3
        mkMapView.addGestureRecognizer(gestureRecognizer)
        
        let keyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(keyboard)
        
        if selectedTitle != "" {
            //CoreData
            saveClicked.isHidden = true
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleId?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String {
                            annatationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annatationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annatationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annatationLongitude = longitude
                                        
                                        let annatation = MKPointAnnotation()
                                        annatation.title = annatationTitle
                                        annatation.subtitle = annatationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annatationLatitude, longitude: annatationLongitude)
                                        annatation.coordinate = coordinate
                                        mkMapView.addAnnotation(annatation)
                                        nameText.text = annatationTitle
                                        commentText.text = annatationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mkMapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error")
            }
            
        } else {
        }
    }
    
    @objc func hideKeyboard() {
        
        view.endEditing(true)
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.mkMapView)
            let touchCoordinate = self.mkMapView.convert(touchPoint, toCoordinateFrom: self.mkMapView)
            chosenLatitude = touchCoordinate.latitude
            chosenLongitude = touchCoordinate.longitude
            
            let annatation = MKPointAnnotation()
            annatation.coordinate = touchCoordinate
            annatation.title = nameText.text
            annatation.subtitle = commentText.text
            self.mkMapView.addAnnotation(annatation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == "" {
            let locations = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: locations, span: span)
            mkMapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "My Annotation"
        var pinView = mkMapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annatationLatitude, longitude: annatationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                //closure
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annatationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    @IBAction func saveClicked(_ sender: Any) {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("Success")
        } catch {
            print("Error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newPlace") , object: nil)
        navigationController?.popViewController(animated: true)
        
    }
}
