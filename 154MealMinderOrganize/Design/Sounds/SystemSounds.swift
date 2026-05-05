import AudioToolbox

enum SystemSounds {
    static func play(_ id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }

    static let successPing: SystemSoundID = 1057
    static let favoriteAdded: SystemSoundID = 1104
    static let groceryChecked: SystemSoundID = 1009
    static let timerComplete: SystemSoundID = 1016
    static let interfaceTick: SystemSoundID = 1003
}
