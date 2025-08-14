import SwiftUI
import MapKit
import WMFData

struct WMFYearInReviewMapView: View {
    @Binding var locationName: String?
    @Binding var randomArticles: [String]
    
    let locationArticles: [WMFLegacyPageView]
    
    var body: some View {
        YearInReviewMapView(locationName: $locationName, randomArticles: $randomArticles, locationArticles: locationArticles)
            .edgesIgnoringSafeArea(.all)
    }
}

private struct YearInReviewMapView: UIViewRepresentable {
    @Binding var locationName: String?
    @Binding var randomArticles: [String]
    let locationArticles: [WMFLegacyPageView]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "marker")
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")
        
        // Add annotations for each article
        let annotations = locationArticles.map { article -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: article.latitude, longitude: article.longitude)
            annotation.title = article.title
            return annotation
        }
        mapView.addAnnotations(annotations)
        
        mapView.setVisibleMapRect(MKMapRect.world, animated: false)
        mapView.isZoomEnabled = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: YearInReviewMapView
        private var didZoomToLargestCluster = false

        init(_ parent: YearInReviewMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let cluster = annotation as? MKClusterAnnotation {
                let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: "cluster") as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: "cluster")
                clusterView.canShowCallout = true
                clusterView.markerTintColor = .purple
                clusterView.glyphText = "\(cluster.memberAnnotations.count)"
                return clusterView
            }

            let markerView = mapView.dequeueReusableAnnotationView(withIdentifier: "marker") as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
            markerView.canShowCallout = true
            markerView.clusteringIdentifier = "clusterID"
            return markerView
        }

        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            guard !didZoomToLargestCluster else { return }

            // Schedule a check on the next run loop so clusters have time to form
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let clusters = mapView.annotations.compactMap { $0 as? MKClusterAnnotation }
                if let largestCluster = clusters.max(by: { $0.memberAnnotations.count < $1.memberAnnotations.count }) {
                    
                    let annotations = largestCluster.memberAnnotations
                    
                    // Grab some article titles
                    var allTitles = annotations.compactMap { $0.title }.compactMap { $0 }
                    let randomThree = Array(allTitles.shuffled().prefix(3))
                    
                    let rect = annotations.reduce(MKMapRect.null) { $0.union(MKMapRect(origin: MKMapPoint($1.coordinate), size: MKMapSize(width: 0, height: 0))) }
                    mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
                    
                    // wait for animation to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.getClusterLocationName(cluster: largestCluster) { [weak self] name in
                            if let name = name {
                                self?.parent.locationName = name
                                self?.parent.randomArticles = randomThree
                            }
                        }
                    }
                    

                    self.didZoomToLargestCluster = true
                }
            }
        }
        
        func getClusterLocationName(cluster: MKClusterAnnotation, completion: @escaping (String?) -> Void) {
            let coordinates = cluster.memberAnnotations.map { $0.coordinate }

            guard !coordinates.isEmpty else {
                completion(nil)
                return
            }

            // Compute average coordinate for the cluster
            let avgLat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
            let avgLon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
            let location = CLLocation(latitude: avgLat, longitude: avgLon)

            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first, error == nil else {
                    completion(nil)
                    return
                }

                // Construct a readable location name
//                if let city = placemark.locality, let state = placemark.administrativeArea {
//                    completion("\(city), \(state)")
//                } else if let subAdmin = placemark.subAdministrativeArea, let state = placemark.administrativeArea {
//                    completion("\(subAdmin), \(state)")
                
//                if let state = placemark.administrativeArea, let country = placemark.country {
//                    completion("\(state), \(country)")
//                } else
                
                if let country = placemark.country {
                    completion(country)
                } else if let ocean = placemark.ocean {
                    completion(ocean)
                } else {
                    completion(nil)
                }
            }
        }
    }
}
