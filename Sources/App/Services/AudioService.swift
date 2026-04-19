import AVFoundation
import Foundation

final class AudioService {
    private var recorder: AVAudioRecorder?

    private var outputURL: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("Dicto", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("recording.wav")
    }

    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 16_000.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
    ]

    func startRecording() {
        let url = outputURL
        recorder = try? AVAudioRecorder(url: url, settings: recordingSettings)
        recorder?.record()
    }

    @discardableResult
    func stopRecording() -> URL? {
        recorder?.stop()
        let url = recorder?.url
        recorder = nil
        return url
    }
}
