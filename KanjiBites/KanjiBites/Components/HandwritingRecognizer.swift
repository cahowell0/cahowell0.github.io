@preconcurrency import PencilKit
import UIKit
import Vision

enum HandwritingRecognizerError: Error, LocalizedError {
    case noImageData
    case requestFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noImageData: return "Could not render drawing to image."
        case .requestFailed(let e): return e.localizedDescription
        }
    }
}

struct HandwritingRecognizer {
    static func recognize(
        drawing: PKDrawing,
        canvasSize: CGSize,
        completion: @escaping @Sendable (Result<String, HandwritingRecognizerError>) -> Void
    ) {
        let rect = CGRect(origin: .zero, size: canvasSize)
        let scale = UIScreen.main.scale
        let image = drawing.image(from: rect, scale: scale)

        guard let cgImage = image.cgImage else {
            completion(.failure(.noImageData))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(.requestFailed(error))) }
                return
            }
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined()
            DispatchQueue.main.async { completion(.success(text)) }
        }

        // Fix language to Japanese — automaticallyDetectsLanguage overrides recognitionLanguages on iOS 16+
        request.recognitionLanguages = ["ja"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { completion(.failure(.requestFailed(error))) }
            }
        }
    }
}
