import AVFoundation
import CoreAudio

final class SystemAudioCapture: AudioSource {
    var onSamples: (([Float]) -> Void)?

    private let sampleQueue = DispatchQueue(label: "transcript.systemaudio")
    private var tapID = AudioObjectID(kAudioObjectUnknown)
    private var aggregateID = AudioObjectID(kAudioObjectUnknown)
    private var procID: AudioDeviceIOProcID?

    func start() throws {
        do {
            try startTap()
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        if let procID {
            AudioDeviceStop(aggregateID, procID)
            AudioDeviceDestroyIOProcID(aggregateID, procID)
        }
        AudioHardwareDestroyAggregateDevice(aggregateID)
        AudioHardwareDestroyProcessTap(tapID)
        procID = nil
        aggregateID = AudioObjectID(kAudioObjectUnknown)
        tapID = AudioObjectID(kAudioObjectUnknown)
    }

    private func startTap() throws {
        let tap = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
        tap.uuid = UUID()
        tap.isPrivate = true
        try check(AudioHardwareCreateProcessTap(tap, &tapID))

        let aggregate: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Transcript System Audio",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapDriftCompensationKey: true,
                kAudioSubTapUIDKey: tap.uuid.uuidString
            ]]
        ]
        try check(AudioHardwareCreateAggregateDevice(aggregate as CFDictionary, &aggregateID))

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyFormat,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var description = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        try check(AudioObjectGetPropertyData(tapID, &address, 0, nil, &size, &description))
        guard let format = AVAudioFormat(streamDescription: &description) else { throw failure(kAudioHardwareUnsupportedOperationError) }
        guard let resampler = AudioResampler(from: format) else { throw failure(kAudioHardwareUnsupportedOperationError) }

        try check(AudioDeviceCreateIOProcIDWithBlock(&procID, aggregateID, sampleQueue) { [weak self] _, input, _, _, _ in
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: input, deallocator: nil) else { return }
            guard let samples = resampler.resample(buffer) else { return }
            self?.onSamples?(samples)
        })
        try check(AudioDeviceStart(aggregateID, procID))
    }

    private func check(_ status: OSStatus) throws {
        guard status != noErr else { return }
        throw failure(status)
    }

    private func failure(_ status: OSStatus) -> NSError {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
}
