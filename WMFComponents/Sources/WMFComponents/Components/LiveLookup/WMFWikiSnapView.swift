import AVFoundation
import Vision
import SwiftUI
import MapKit

@available(iOS 18.0, *)
public struct WMFWikiSnapView: View {
    @SwiftUI.State private var classifications = [String]()
    @SwiftUI.State private var isClassifying = false
    @SwiftUI.State private var errorMessage: String?
    @SwiftUI.State private var wikiResults: [WikiResult] = []
    @SwiftUI.State private var shareURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var cameraManager = CameraManager()
    
    private let onArticleTap: (URL) -> Void
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    public init(onArticleTap: @escaping (URL) -> Void) {
        self.onArticleTap = onArticleTap
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: Live camera feed
                CameraPreviewView(session: cameraManager.session)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // MARK: Overlay content
                VStack {
                    topBar
                    Spacer()
                    centerContent
                }
                .frame(height: .infinity)
                .padding()
                .frame(width: geometry.size.width)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            cameraManager.startSession()
            startClassificationLoop()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(item: $shareURL) { url in
            ShareSheet(activityItems: [url])
        }
    }
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("X")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            
            Text("WikiSnap")
                .font(.title)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
    
    private var centerContent: some View {
        VStack(spacing: 12) {
            if isClassifying && wikiResults.isEmpty {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            } else if wikiResults.isEmpty {
                Text("Point your camera at something")
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            } else {
                // First result (featured)
                if let result = wikiResults.first {
                    HStack(spacing: 0) {
                        Button {
                            onArticleTap(result.articleURL)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(result.title)
                                            .font(.headline)
                                        if result.isLocationBased {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(Color(uiColor: WMFColor.blue700))
                                        }
                                        if let confidence = result.confidence {
                                            Text("\(Int(confidence * 100))%")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text(result.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            shareURL = result.articleURL
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                        .buttonStyle(.plain)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                
                if wikiResults.count > 1 {
                    Text("Other articles")
                        .font(Font((WMFFont.for(.semiboldCaption1))))
                        .foregroundStyle(Color(uiColor: theme.paperBackground))
                    
                    // Remaining results
                    VStack {
                        ForEach(wikiResults.dropFirst()) { result in
                            Button {
                                onArticleTap(result.articleURL)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(result.title)
                                                .font(.subheadline)
                                            if result.isLocationBased {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundStyle(Color(uiColor: WMFColor.blue700))
                                            }
                                            if let confidence = result.confidence {
                                                Text("\(Int(confidence * 100))%")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Text(result.summary)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                    
                                    Button {
                                        shareURL = result.articleURL
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
    }
    
    // MARK: - Classification Loop
    
    private func startClassificationLoop() {
        Task {
            // Initial delay to let camera warm up
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            while !Task.isCancelled {
                await classifyCurrentFrame()
                // Wait before next classification (adjust interval as needed)
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
    }
    
    private func classifyCurrentFrame() async {
        guard let pixelBuffer = cameraManager.currentFrame else {
            return
        }
        
        isClassifying = true
        errorMessage = nil
        
        do {
            if let observations = try await classify(pixelBuffer) {
                let filtered = observations.filter { $0.confidence > 0.1 }
                
                var newResults: [WikiResult] = []
                for observation in filtered.prefix(5) {
                    if let result = try await fetchWikiSummary(for: observation.identifier, confidence: observation.confidence) {
                        newResults.append(result)
                    }
                }
                
                if !newResults.isEmpty {
                    wikiResults = Array(newResults.prefix(4))
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isClassifying = false
    }
    
    private func classify(_ pixelBuffer: CVPixelBuffer) async throws -> [ClassificationObservation]? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let request = ClassifyImageRequest()
        return try await request.perform(on: ciImage)
    }
    
    // MARK: - MapKit Search
    
    private func searchNearbyPointsOfInterest(at coordinate: CLLocationCoordinate2D) async -> [String] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "landmark"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            return response.mapItems.compactMap { $0.name }
        } catch {
            print("MapKit search error: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Wikipedia API
    
    private func fetchWikiSummary(for searchTerm: String, isLocationBased: Bool = false, confidence: Float? = nil) async throws -> WikiResult? {
        let encoded = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? searchTerm
        let urlString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let decoded = try JSONDecoder().decode(WikiSummaryResponse.self, from: data)
        return WikiResult(
            title: decoded.title,
            summary: decoded.extract,
            articleURL: decoded.contentUrls.desktop.page,
            isLocationBased: isLocationBased,
            confidence: confidence
        )
    }
}

// MARK: - Camera Manager

@available(iOS 18.0, *)
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    @Published var currentFrame: CVPixelBuffer?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Failed to access camera")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.output.queue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // Set video orientation
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

@available(iOS 18.0, *)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentFrame = pixelBuffer
        }
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - URL + Identifiable

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Models

struct WikiResult: Identifiable {
    var id: String { title }
    let title: String
    let summary: String
    let articleURL: URL
    var isLocationBased: Bool = false
    var confidence: Float?
}

struct WikiSummaryResponse: Decodable {
    let title: String
    let extract: String
    let contentUrls: ContentUrls
    
    enum CodingKeys: String, CodingKey {
        case title, extract
        case contentUrls = "content_urls"
    }
}

struct ContentUrls: Decodable {
    let desktop: DesktopUrl
}

struct DesktopUrl: Decodable {
    let page: URL
}
