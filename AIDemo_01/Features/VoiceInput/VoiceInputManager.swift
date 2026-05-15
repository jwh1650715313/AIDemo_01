import AVFoundation
import Foundation
import Speech

// 语音输入管理器：只封装 Apple Speech.framework、麦克风采集和识别生命周期，不依赖聊天 UI。
@MainActor
final class VoiceInputManager {
    static let shared = VoiceInputManager()

    enum State: Equatable {
        case idle
        case requestingPermission
        case ready
        case listening
        case stopping
        case cancelled
        case failed
    }

    enum VoiceInputError: LocalizedError, Equatable {
        case microphonePermissionDenied
        case speechPermissionDenied
        case speechRecognitionUnavailable
        case unsupportedLocale(String)
        case audioSessionFailed(String)
        case recognitionFailed(String)

        var errorDescription: String? {
            switch self {
            case .microphonePermissionDenied:
                return "麦克风权限未开启，请在系统设置中允许访问麦克风。"
            case .speechPermissionDenied:
                return "语音识别权限未开启，请在系统设置中允许使用语音识别。"
            case .speechRecognitionUnavailable:
                return "当前设备或系统语音识别服务不可用，请稍后重试。"
            case .unsupportedLocale(let localeIdentifier):
                return "当前系统不支持 \(localeIdentifier) 中文语音识别。"
            case .audioSessionFailed(let message):
                return "麦克风启动失败：\(message)"
            case .recognitionFailed(let message):
                return "识别失败：\(message)"
            }
        }
    }

    var onStateChange: ((State) -> Void)?
    var onRecognizedText: ((String) -> Void)?
    var onPartialText: ((String) -> Void)?
    var onFinalText: ((String) -> Void)?
    var onAudioEnergyChange: (([Float]) -> Void)?
    var onError: ((VoiceInputError) -> Void)?

    private let localeIdentifier: String
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private var startTask: Task<Void, Never>?
    private var isInputTapInstalled = false
    private var isStoppingByUser = false

    private(set) var state: State = .idle
    private(set) var currentText = ""

    init(localeIdentifier: String = "zh-CN") {
        self.localeIdentifier = localeIdentifier
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }

    deinit {
        startTask?.cancel()
        speechRecognitionTask?.cancel()
        recognitionRequest?.endAudio()
        if isInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }

    // 请求语音识别权限，调用方可在开始识别前主动触发。
    func requestSpeechRecognitionPermission() async -> Bool {
        await requestSpeechAuthorizationStatus() == .authorized
    }

    // 请求麦克风权限，调用方可在开始识别前主动触发。
    func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // 开始中文实时语音识别，使用 zh-CN 的系统识别器。
    func startListening() {
        guard state != .requestingPermission, state != .listening, state != .stopping else { return }

        startTask?.cancel()
        stopAudioResources(endAudio: true, cancelTask: true, deactivateSession: true)

        currentText = ""
        isStoppingByUser = false
        onRecognizedText?("")
        onPartialText?("")
        updateState(.requestingPermission)

        startTask = Task { [weak self] in
            await self?.beginListening()
        }
    }

    // 停止识别并返回当前最终文本，适合发送按钮使用。
    @discardableResult
    func stopListening() async -> String {
        let finalText = normalizedText(currentText)

        guard startTask != nil || speechRecognitionTask != nil || audioEngine.isRunning else {
            onFinalText?(finalText)
            return finalText
        }

        isStoppingByUser = true
        updateState(.stopping)
        startTask?.cancel()
        startTask = nil
        stopAudioResources(endAudio: true, cancelTask: true, deactivateSession: true)
        updateState(.ready)
        onFinalText?(finalText)
        return finalText
    }

    // 取消识别并丢弃当前文本，用于用户点击取消。
    func cancelListening() async {
        isStoppingByUser = true
        startTask?.cancel()
        startTask = nil
        stopAudioResources(endAudio: true, cancelTask: true, deactivateSession: true)
        currentText = ""
        onRecognizedText?("")
        onPartialText?("")
        updateState(.cancelled)
    }

    // 兼容旧调用点，实际实现已切换为 Speech.framework。
    func startRecognition() {
        startListening()
    }

    // 兼容旧调用点，实际实现已切换为 Speech.framework。
    @discardableResult
    func stopRecognition() async -> String {
        await stopListening()
    }

    // 兼容旧调用点，实际实现已切换为 Speech.framework。
    func cancelRecognition() async {
        await cancelListening()
    }

    private func beginListening() async {
        defer {
            startTask = nil
        }

        do {
            guard let speechRecognizer else {
                throw VoiceInputError.unsupportedLocale(localeIdentifier)
            }

            guard speechRecognizer.isAvailable else {
                throw VoiceInputError.speechRecognitionUnavailable
            }

            let speechStatus = await requestSpeechAuthorizationStatus()
            try Task.checkCancellation()
            guard speechStatus == .authorized else {
                throw VoiceInputError.speechPermissionDenied
            }

            guard await requestMicrophonePermission() else {
                throw VoiceInputError.microphonePermissionDenied
            }
            try Task.checkCancellation()

            try startAudioEngine(with: speechRecognizer)
            updateState(.listening)
        } catch is CancellationError {
            // 用户主动停止或取消时保持静默，避免重复错误回调。
        } catch let error as VoiceInputError {
            handleError(error)
        } catch {
            handleError(.recognitionFailed(error.localizedDescription))
        }
    }

    private func requestSpeechAuthorizationStatus() async -> SFSpeechRecognizerAuthorizationStatus {
        let status = SFSpeechRecognizer.authorizationStatus()

        switch status {
        case .authorized, .denied, .restricted:
            return status
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        @unknown default:
            return .denied
        }
    }

    private func startAudioEngine(with speechRecognizer: SFSpeechRecognizer) throws {
        stopAudioResources(endAudio: true, cancelTask: true, deactivateSession: false)

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw VoiceInputError.audioSessionFailed(error.localizedDescription)
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }
        recognitionRequest = request

        speechRecognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let errorInfo = error.map { Self.recognitionErrorInfo(from: $0) }

            Task { @MainActor [weak self] in
                self?.handleRecognitionUpdate(text: text, isFinal: isFinal, errorInfo: errorInfo)
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw VoiceInputError.audioSessionFailed("当前设备没有可用的麦克风输入。")
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)

            let levels = Self.audioLevels(from: buffer)
            guard !levels.isEmpty else { return }
            Task { @MainActor [weak self] in
                self?.onAudioEnergyChange?(levels)
            }
        }
        isInputTapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopAudioResources(endAudio: true, cancelTask: true, deactivateSession: true)
            throw VoiceInputError.audioSessionFailed(error.localizedDescription)
        }
    }

    private func handleRecognitionUpdate(
        text: String?,
        isFinal: Bool,
        errorInfo: RecognitionErrorInfo?
    ) {
        if let text {
            let nextText = normalizedText(text)
            currentText = nextText
            onRecognizedText?(nextText)
            onPartialText?(nextText)

            if isFinal {
                onFinalText?(nextText)
            }
        }

        if isFinal, !isStoppingByUser {
            stopAudioResources(endAudio: false, cancelTask: false, deactivateSession: true)
            updateState(.ready)
            return
        }

        guard let errorInfo, !isStoppingByUser, !errorInfo.isCancellation else { return }
        handleError(.recognitionFailed(errorInfo.message))
    }

    private func stopAudioResources(
        endAudio: Bool,
        cancelTask: Bool,
        deactivateSession: Bool
    ) {
        if isInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isInputTapInstalled = false
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if endAudio {
            recognitionRequest?.endAudio()
        }

        if cancelTask {
            speechRecognitionTask?.cancel()
        }

        speechRecognitionTask = nil
        recognitionRequest = nil
        audioEngine.reset()

        if deactivateSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func normalizedText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleError(_ error: VoiceInputError) {
        startTask?.cancel()
        startTask = nil
        stopAudioResources(endAudio: true, cancelTask: true, deactivateSession: true)
        updateState(.failed)
        onError?(error)
    }

    private func updateState(_ newState: State) {
        guard state != newState else { return }
        state = newState
        onStateChange?(newState)
    }

    private struct RecognitionErrorInfo: Sendable {
        let message: String
        let isCancellation: Bool
    }

    private nonisolated static func recognitionErrorInfo(from error: Error) -> RecognitionErrorInfo {
        let nsError = error as NSError
        let isCancellation = nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError
        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if message.isEmpty {
            return RecognitionErrorInfo(message: "系统语音识别返回未知错误。", isCancellation: isCancellation)
        }

        return RecognitionErrorInfo(message: message, isCancellation: isCancellation)
    }

    private nonisolated static func audioLevels(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard channelCount > 0, frameLength > 0 else { return [] }

        let sampleStride = max(frameLength / 256, 1)
        var squaredSum: Float = 0
        var sampleCount: Float = 0

        for channel in 0..<channelCount {
            let samples = channelData[channel]
            var frame = 0
            while frame < frameLength {
                let sample = samples[frame]
                squaredSum += sample * sample
                sampleCount += 1
                frame += sampleStride
            }
        }

        guard sampleCount > 0 else { return [] }

        let rms = sqrt(squaredSum / sampleCount)
        let baseLevel = min(max(rms * 12, 0.06), 1.0)

        // 中文注释：返回一组轻微错落的能量值，复用原有声波 UI，不改变面板设计。
        return (0..<18).map { index in
            let variation = 0.82 + Float(index % 6) * 0.045
            return min(max(baseLevel * variation, 0.06), 1.0)
        }
    }
}
