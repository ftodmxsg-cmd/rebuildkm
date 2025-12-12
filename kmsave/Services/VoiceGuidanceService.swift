import Foundation
import AVFoundation
import Combine

/// Service for providing voice guidance during navigation
class VoiceGuidanceService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    // MARK: - Properties
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isEnabled = true
    @Published var isSpeaking = false
    
    // MARK: - Initialization
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        print("🗣️ DEBUG: VoiceGuidanceService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Announce a navigation instruction
    func announce(instruction: String, distance: Int) {
        guard isEnabled else { return }
        
        let announcement = formatAnnouncement(instruction: instruction, distance: distance)
        speak(announcement)
    }
    
    /// Announce arrival at destination
    func announceArrival() {
        speak("You have arrived at your destination")
    }
    
    /// Announce user went off route
    func announceOffRoute() {
        speak("You are off route. Recalculating...")
    }
    
    /// Stop current speech
    func stopSpeaking() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            print("🗣️ DEBUG: Stopped speaking")
        }
    }
    
    /// Enable or disable voice guidance
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopSpeaking()
        }
        print("🗣️ DEBUG: Voice guidance \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Private Methods
    
    private func speak(_ text: String) {
        // Stop any current speech
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Speak
        synthesizer.speak(utterance)
        isSpeaking = true
        
        print("🗣️ DEBUG: Speaking: \(text)")
    }
    
    private func formatAnnouncement(instruction: String, distance: Int) -> String {
        // Format instruction into natural speech
        var cleanInstruction = instruction
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add distance prefix if distance > 0
        if distance > 0 {
            let distanceText = formatDistanceForSpeech(distance)
            return "In \(distanceText), \(cleanInstruction)"
        } else {
            return cleanInstruction
        }
    }
    
    private func formatDistanceForSpeech(_ meters: Int) -> String {
        if meters < 100 {
            return "\(meters) meters"
        } else if meters < 1000 {
            // Round to nearest 50 meters
            let rounded = (meters / 50) * 50
            return "\(rounded) meters"
        } else {
            // Convert to kilometers
            let km = Double(meters) / 1000.0
            if km < 2.0 {
                return String(format: "%.1f kilometers", km)
            } else {
                return String(format: "%.0f kilometers", km)
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            print("🗣️ DEBUG: Audio session configured")
        } catch {
            print("❌ ERROR: Failed to configure audio session - \(error)")
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        print("🗣️ DEBUG: Started speaking")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        print("🗣️ DEBUG: Finished speaking")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        print("🗣️ DEBUG: Speech cancelled")
    }
}

