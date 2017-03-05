import UIKit

public func show(whisper message: Message, to: UINavigationController, action: WhisperAction = .show, animate: Bool = true) {
    whisperFactory.craft(message, navigationController: to, action: action, animate: animate)
}

public func show(shout announcement: Announcement, to: UIViewController, completion: (() -> Void)? = nil) {
    shoutView.craft(announcement, to: to, completion: completion)
}

public func show(whistle murmur: Murmur, action: WhistleAction = .show(1.5)) {
    whistleFactory.whistler(murmur, action: action)
}

public func hide(whisperFrom from: UINavigationController, after: TimeInterval = 0, animate: Bool = true) {
    whisperFactory.silentWhisper(from, after: after, animate: animate)
}

public func hide(whistleAfter after: TimeInterval = 0) {
    whistleFactory.calm(after: after)
}
