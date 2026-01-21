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
                    Spacer()
                    bottomContent(geometry: geometry)
                }
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
    
    private func bottomContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            if isClassifying && wikiResults.isEmpty {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 40)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 40)
            } else if wikiResults.isEmpty {
                Text("Point your camera at something")
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 40)
            } else {
                // Horizontal scrolling cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(wikiResults) { result in
                            ArticleCard(
                                result: result,
                                onReadArticle: { onArticleTap(result.articleURL) },
                                onShare: { shareURL = result.articleURL }
                            )
                            .frame(width: geometry.size.width * 0.75, height: 280)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Classification Loop
    
    private func startClassificationLoop() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            while !Task.isCancelled {
                await classifyCurrentFrame()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
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
            thumbnailURL: decoded.thumbnail?.source,
            isLocationBased: isLocationBased,
            confidence: confidence
        )
    }
}

// MARK: - Article Card

@available(iOS 18.0, *)
struct ArticleCard: View {
    let result: WikiResult
    let onReadArticle: () -> Void
    let onShare: () -> Void
    
    private func confidenceColor(for confidence: Float) -> Color {
        let percentage = Int(confidence * 100)
        switch percentage {
        case 0...29:
            return Color(uiColor: WMFColor.red600)
        case 30...80:
            return Color(uiColor: WMFColor.orange600)
        default:
            return Color(uiColor: WMFColor.green600)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and confidence
            HStack(alignment: .top) {
                Text(result.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    // .lineLimit(1)
                
                Spacer()
                
                if let confidence = result.confidence {
                    Text("\(Int(confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(confidenceColor(for: confidence))
                        .cornerRadius(10)
                }
            }
            
            // Summary
            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                // .lineLimit(5)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: onReadArticle) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                        Text("Read article")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(18)
                }
                
                Button(action: onShare) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
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
    var thumbnailURL: URL?
    var isLocationBased: Bool = false
    var confidence: Float?
}

struct WikiSummaryResponse: Decodable {
    let title: String
    let extract: String
    let contentUrls: ContentUrls
    let thumbnail: WikiThumbnail?
    
    enum CodingKeys: String, CodingKey {
        case title, extract, thumbnail
        case contentUrls = "content_urls"
    }
}

struct WikiThumbnail: Decodable {
    let source: URL
    let width: Int
    let height: Int
}

struct ContentUrls: Decodable {
    let desktop: DesktopUrl
}

struct DesktopUrl: Decodable {
    let page: URL
}
