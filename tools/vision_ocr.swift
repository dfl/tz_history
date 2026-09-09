// Apple Vision OCR CLI: prints one line per recognized text observation as
//   <text>\t<x>\t<y>\t<w>\t<h>   (pixel coords, origin TOP-left)
// On-device (no cloud -> copyright-safe), and far stronger than tesseract on faint print.
//   swift tools/vision_ocr.swift <image.png>
import Foundation
import Vision
import AppKit

guard CommandLine.arguments.count > 1,
      let img = NSImage(contentsOfFile: CommandLine.arguments[1]),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { exit(1) }
let W = CGFloat(cg.width), H = CGFloat(cg.height)
let req = VNRecognizeTextRequest { req, _ in
  for obs in (req.results as? [VNRecognizedTextObservation] ?? []) {
    guard let t = obs.topCandidates(1).first?.string else { continue }
    let b = obs.boundingBox // normalized, origin BOTTOM-left
    let x = Int(b.minX * W), y = Int((1 - b.maxY) * H), w = Int(b.width * W), h = Int(b.height * H)
    print("\(t)\t\(x)\t\(y)\t\(w)\t\(h)")
  }
}
req.recognitionLevel = .accurate
req.usesLanguageCorrection = false
try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
