import FluidAudio
import Foundation

actor FluidAudioLabeler: SpeakerIdentifying {
    private var diarizer: DiarizerManager?
    private var speakerNames: [String: String] = [:]

    func load() async throws {
        guard diarizer == nil else { return }
        let models = try await DiarizerModels.downloadIfNeeded()
        var config = DiarizerConfig.default
        config.minSpeechDuration = 0.5
        let manager = DiarizerManager(config: config)
        manager.initialize(models: models)
        diarizer = manager
    }

    func label(for samples: [Float]) async -> String? {
        do {
            try await load()
            guard let diarizer else { return nil }
            let result = try diarizer.performCompleteDiarization(samples)
            let durations = result.segments.reduce(into: [String: Float]()) {
                $0[$1.speakerId, default: 0] += $1.durationSeconds
            }
            guard let dominant = durations.max(by: { $0.value < $1.value })?.key else {
                return nil
            }
            if speakerNames[dominant] == nil {
                speakerNames[dominant] = "화자\(speakerNames.count + 1)"
            }
            return speakerNames[dominant]
        } catch {
            return nil
        }
    }
}
