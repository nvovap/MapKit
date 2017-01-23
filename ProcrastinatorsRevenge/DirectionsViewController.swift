/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import MapKit
import CoreLocation

class DirectionsViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var totalTimeLabel: UILabel!
  @IBOutlet weak var directionsTableView: DirectionsTableView!
  
  var activityIndicator: UIActivityIndicatorView?
  var locationArray: [(textField: UITextField, mapItem: MKMapItem?)]!
  
    func displayDirections(_ directionsArray: [(startingAddress: String,
        endingAddress: String, route: MKRoute)]) {
        directionsTableView.directionsArray = directionsArray
        directionsTableView.delegate = directionsTableView
        directionsTableView.dataSource = directionsTableView
        directionsTableView.reloadData()
    }
    
    
    func calculateSegmentDirections(index: Int,
                                    time: TimeInterval, distance: CLLocationDistance, routes: [MKRoute]) {
        // 1
        var time = time
        var distance = distance
        var routes = routes
        let request: MKDirectionsRequest = MKDirectionsRequest()
       
        
        request.source = locationArray[index].mapItem
        request.destination = locationArray[index+1].mapItem
        // 2
        request.requestsAlternateRoutes = true
        // 3
        request.transportType = .automobile
        
        
        
        
        
        // 4
        let directions = MKDirections(request: request)
        
        
        directions.calculate { (response, error) in
            if (response?.routes) != nil {
                
                if let routeResponse = response?.routes {
                    let quickestRouteForSegment: MKRoute =
                        routeResponse.sorted(by: {$0.expectedTravelTime <
                            $1.expectedTravelTime})[0]
                    
                    routes.append(quickestRouteForSegment)
                    time += quickestRouteForSegment.expectedTravelTime
                    distance += quickestRouteForSegment.distance
                    
                    if index+2 < self.locationArray.count {
                        self.calculateSegmentDirections(index: index+1, time: time, distance: distance, routes: routes)
                    } else {
                        self.hideActivityIndicator()
                        self.showRoute(routes, time: time, distance: distance)
                    }
                }
                
                
            } else if let _ = error {
                let alert = UIAlertController(title: nil, message: "Directions not available.", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "OK", style: .cancel, handler: { (alert) in
                    self.navigationController!.popViewController(animated: true)
                })
                
                alert.addAction(okButton)
                self.present(alert, animated: true, completion: nil)
                
            }
        }
        
        
        
        
    }
    
    func printTimeToLabel(_ time: TimeInterval, distance: CLLocationDistance) {
        let timeString = time.formatted()
        totalTimeLabel.text = " Total Distance: \(Int(distance/1000)) Total Time: \(timeString)"
    }
    
    func showRoute(_ routes: [MKRoute], time: TimeInterval, distance: CLLocationDistance) {
        var directionsArray = [(startingAddress: String, endingAddress: String, route: MKRoute)]()
        
        for i in 0..<routes.count {
            let route = routes[i]
            
            plotPolyline(route: route)
            
            let adress = locationArray[i+1].textField.text!
            
            directionsArray.append((locationArray[i].textField.text!, adress, route: route))
        }
        displayDirections(directionsArray)
        
        printTimeToLabel(time, distance: distance)
    }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    directionsTableView.contentInset = UIEdgeInsetsMake(-36, 0, -20, 0)
    
    addActivityIndicator()
    calculateSegmentDirections(index: 0, time: 0, distance: 0, routes: [])
  }

  func addActivityIndicator() {
    activityIndicator = UIActivityIndicatorView(frame: UIScreen.main.bounds)
    activityIndicator?.activityIndicatorViewStyle = .whiteLarge
    activityIndicator?.backgroundColor = view.backgroundColor
    activityIndicator?.startAnimating()
    view.addSubview(activityIndicator!)
  }
  
  func hideActivityIndicator() {
    if activityIndicator != nil {
      activityIndicator?.removeFromSuperview()
      activityIndicator = nil
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    navigationController?.isNavigationBarHidden = false
    automaticallyAdjustsScrollViewInsets = false
  }
    
    
    
    
    func plotPolyline(route: MKRoute) {
        // 1
        mapView.add(route.polyline)
        // 2
        if mapView.overlays.count == 1 {
            mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                      edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                      animated: false)
        }
            // 3
        else {
            let polylineBoundingRect =  MKMapRectUnion(mapView.visibleMapRect,
                                                       route.polyline.boundingMapRect)
            mapView.setVisibleMapRect(polylineBoundingRect,
                                      edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                      animated: false)
        }
    }
    
}

extension DirectionsViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    
    let polylineRenderer = MKPolylineRenderer(overlay: overlay)
    if (overlay is MKPolyline) {
        if mapView.overlays.count == 1 {
            polylineRenderer.strokeColor =
                UIColor.blue.withAlphaComponent(0.75)
        } else if mapView.overlays.count == 2 {
            polylineRenderer.strokeColor =
                UIColor.green.withAlphaComponent(0.75)
        } else if mapView.overlays.count == 3 {
            polylineRenderer.strokeColor =
                UIColor.red.withAlphaComponent(0.75)
        }
        polylineRenderer.lineWidth = 5
    }
    return polylineRenderer
  }
}
