import UIKit

public enum WhisperAction: String {
    case present = "Whisper.PresentNotification"
    case show = "Whisper.ShowNotification"
}

let whisperFactory: WhisperFactory = WhisperFactory()

class WhisperFactory: NSObject {
    
    struct AnimationTiming {
        static let movement: TimeInterval = 0.3
        static let switcher: TimeInterval = 0.1
        static let popUp: TimeInterval = 1.5
        static let loaderDuration: TimeInterval = 0.7
        static let totalDelay: TimeInterval = popUp + movement * 2
    }
    
    weak var navigationController: UINavigationController?
    var edgeInsetHeight: CGFloat = 0
    var whisperView: WhisperView!
    var delayTimer = Timer()
    var presentTimer = Timer()
    var navigationStackCount = 0
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(WhisperFactory.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    func craft(_ message: Message, navigationController: UINavigationController, action: WhisperAction, animate: Bool = true, completion: (() -> Void)? = nil) {
        self.navigationController = navigationController
        self.navigationController?.delegate = self
        presentTimer.invalidate()
        
        var containsWhisper = false
        for subview in navigationController.navigationBar.subviews {
            if let whisper = subview as? WhisperView {
                whisperView = whisper
                containsWhisper = true
                break
            }
        }
        
        if !containsWhisper {
            whisperView = WhisperView(height: navigationController.navigationBar.frame.height, message: message)
            whisperView.frame.size.height = 0
            var maximumY = navigationController.navigationBar.frame.height
            
            whisperView.transformViews.forEach {
                $0.frame.origin.y = -10
                $0.alpha = 0
            }
            
            /*for subview in navigationController.navigationBar.subviews {
             if subview.frame.maxY > maximumY && subview.frame.height > 0 { maximumY = subview.frame.maxY }
             }*/
            
            whisperView.frame.origin.y = maximumY
            navigationController.navigationBar.addSubview(whisperView)
        }
        
        print("CRAFTING", self.navigationController?.topViewController?.navigationItem.title, action, message.title)
        
        if containsWhisper {
            changeView(message, action: action, animate: animate, completion: completion)
        } else {
            switch action {
            case .present:
                presentView(animate: animate, completion: completion)
            case .show:
                showView()
            }
        }
    }
    
    func silentWhisper(_ controller: UINavigationController, after: TimeInterval, animate: Bool = true, completion: (() -> Void)? = nil) {
        self.navigationController = controller
        guard let navigationController = self.navigationController else { return }
        
        var whisperSubview: WhisperView? = nil
        for subview in navigationController.navigationBar.subviews {
            if let whisper = subview as? WhisperView {
                whisperSubview = whisper
                break
            }
        }
        
        if whisperSubview == nil {
            return
        }
        
        print("SILENTING", self.navigationController?.navigationItem.title)
        
        whisperView = whisperSubview
        delayTimer.invalidate()
        var array = ["animate": animate, "completion": completion] as [String : Any]
        delayTimer = Timer.scheduledTimer(timeInterval: after, target: self,
                                          selector: #selector(WhisperFactory.delayFired(_:)), userInfo: array, repeats: false)
    }
    
    // MARK: - Presentation
    
    func doShowView() {
        self.whisperView.frame.size.height = WhisperView.Dimensions.height
        for subview in self.whisperView.transformViews {
            subview.frame.origin.y = 0
            
            if subview == self.whisperView.complementImageView {
                subview.frame.origin.y = (WhisperView.Dimensions.height - WhisperView.Dimensions.imageSize) / 2
            }
            
            subview.alpha = 1
        }
    }
    
    func presentView(animate: Bool = true, completion: (() -> Void)? = nil) {
        moveControllerViews(true)
        
        print("CALLED PRESENTVIEW", animate, completion, self.whisperView)
        if animate {
            UIView.animate(withDuration: AnimationTiming.movement, animations: {
                self.doShowView()
            }, completion: { _ in
                completion?()
            })
        } else {
            self.doShowView()
        }
        
    }
    
    func showView() {
        moveControllerViews(true)
        
        UIView.animate(withDuration: AnimationTiming.movement, animations: {
            self.whisperView.frame.size.height = WhisperView.Dimensions.height
            for subview in self.whisperView.transformViews {
                subview.frame.origin.y = 0
                
                if subview == self.whisperView.complementImageView {
                    subview.frame.origin.y = (WhisperView.Dimensions.height - WhisperView.Dimensions.imageSize) / 2
                }
                
                subview.alpha = 1
            }
        }, completion: { _ in
            self.delayTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self,
                                                   selector: #selector(WhisperFactory.delayFired(_:)), userInfo: nil, repeats: false)
        })
    }
    
    func changeView(_ message: Message, action: WhisperAction, animate: Bool = true, completion: (() -> Void)? = nil) {
        print("CALLED CHANGEVIEW", animate, completion)
        presentTimer.invalidate()
        delayTimer.invalidate()
        hideView(animate: animate)
        
        let title = message.title
        let textColor = message.textColor
        let backgroundColor = message.backgroundColor
        let action = action.rawValue
        
        var array = ["title": title, "textColor" : textColor, "backgroundColor": backgroundColor, "action": action, "animate": animate, "completion": completion] as [String : Any]
        if let images = message.images { array["images"] = images }
        
        presentTimer = Timer.scheduledTimer(timeInterval: (animate) ? AnimationTiming.movement * 1.1 : 0.0, target: self,
                                            selector: #selector(WhisperFactory.presentFired(_:)), userInfo: array, repeats: false)
    }
    
    func doHideView() {
        self.whisperView.frame.size.height = 0
        for subview in self.whisperView.transformViews {
            subview.frame.origin.y = -10
            subview.alpha = 0
        }
    }
    
    func hideView(animate: Bool = true, completion: (() -> Void)? = nil) {
        moveControllerViews(false)
        
        if animate {
            UIView.animate(withDuration: AnimationTiming.movement, animations: {
                self.doHideView()
            }, completion: { _ in
                self.whisperView.removeFromSuperview()
                completion?()
            })
        } else {
            doHideView()
            self.whisperView.removeFromSuperview()
        }
    }
    
    // MARK: - Timer methods
    
    func delayFired(_ timer: Timer) {
        guard let userInfo = timer.userInfo as? [String : AnyObject] else { return }
        hideView(animate: userInfo["animate"] as? Bool ?? true, completion: userInfo["completion"] as? (() -> Void))
    }
    
    func presentFired(_ timer: Timer) {
        guard let navigationController = self.navigationController,
            let userInfo = timer.userInfo as? [String : AnyObject],
            let title = userInfo["title"] as? String,
            let textColor = userInfo["textColor"] as? UIColor,
            let backgroundColor = userInfo["backgroundColor"] as? UIColor,
            let actionString = userInfo["action"] as? String,
            let animate = userInfo["animate"] as? Bool else { return }
        
        var images: [UIImage]? = nil
        
        if let imageArray = userInfo["images"] as? [UIImage]? { images = imageArray }
        
        let action = WhisperAction(rawValue: actionString)
        let message = Message(title: title, textColor: textColor, backgroundColor: backgroundColor, images: images)
        
        whisperView = WhisperView(height: navigationController.navigationBar.frame.height, message: message)
        navigationController.navigationBar.addSubview(whisperView)
        whisperView.frame.size.height = 0
        
        var maximumY = navigationController.navigationBar.frame.height
        
        /*for subview in navigationController.navigationBar.subviews {
         if subview.frame.maxY > maximumY && subview.frame.height > 0 { maximumY = subview.frame.maxY }
         }*/
        
        whisperView.frame.origin.y = maximumY
        
        action == .present ? presentView(animate: animate, completion: userInfo["completion"] as? (() -> Void)) : showView()
    }
    
    // MARK: - Animations
    
    func moveControllerViews(_ down: Bool) {
        print("Config.modifyInset", Config.modifyInset)
        guard let navigationController = self.navigationController,
            let visibleController = navigationController.visibleViewController
            , Config.modifyInset
            else {
                print("NOT MOVING")
                return }
        
        let stackCount = navigationController.viewControllers.count
        
        if down {
            navigationStackCount = stackCount
        } else if navigationStackCount != stackCount {
            return
        }
        
        if !(edgeInsetHeight == WhisperView.Dimensions.height && down) {
            edgeInsetHeight = down ? WhisperView.Dimensions.height : -WhisperView.Dimensions.height
            
            UIView.animate(withDuration: AnimationTiming.movement, animations: {
                self.performControllerMove(visibleController)
            })
        }
    }
    
    func performControllerMove(_ viewController: UIViewController) {
        guard Config.modifyInset else { return }
        
        if let tableView = viewController.view as? UITableView
            , viewController is UITableViewController {
            tableView.contentInset = UIEdgeInsetsMake(tableView.contentInset.top + edgeInsetHeight, tableView.contentInset.left, tableView.contentInset.bottom, tableView.contentInset.right)
        } else if let collectionView = viewController.view as? UICollectionView
            , viewController is UICollectionViewController {
            collectionView.contentInset = UIEdgeInsetsMake(collectionView.contentInset.top + edgeInsetHeight, collectionView.contentInset.left, collectionView.contentInset.bottom, collectionView.contentInset.right)
        } else {
            for view in viewController.view.subviews {
                if let scrollView = view as? UIScrollView {
                    scrollView.contentInset = UIEdgeInsetsMake(scrollView.contentInset.top + edgeInsetHeight, scrollView.contentInset.left, scrollView.contentInset.bottom, scrollView.contentInset.right)
                }
            }
        }
    }
    
    // MARK: - Handling screen orientation
    
    func orientationDidChange() {
        guard let navigationController = self.navigationController else { return }
        for subview in navigationController.navigationBar.subviews {
            guard let whisper = subview as? WhisperView else { continue }
            
            var maximumY = navigationController.navigationBar.frame.height
            /*for subview in navigationController.navigationBar.subviews where subview != whisper {
             if subview.frame.maxY > maximumY && subview.frame.height > 0 { maximumY = subview.frame.maxY }
             }*/
            
            whisper.frame = CGRect(
                x: whisper.frame.origin.x,
                y: maximumY,
                width: UIScreen.main.bounds.width / 3.0,
                height: whisper.frame.size.height)
            whisper.setupFrames()
        }
    }
}

// MARK: UINavigationControllerDelegate

extension WhisperFactory: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        var maximumY = navigationController.navigationBar.frame.maxY - UIApplication.shared.statusBarFrame.height
        
        for subview in navigationController.navigationBar.subviews {
            if subview is WhisperView { navigationController.navigationBar.bringSubview(toFront: subview) }
            
            /*if subview.frame.maxY > maximumY && !(subview is WhisperView) {
             maximumY = subview.frame.maxY
             }*/
        }
        
        whisperView.frame.origin.y = maximumY
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        for subview in navigationController.navigationBar.subviews where subview is WhisperView {
            moveControllerViews(true)
            
            if let index = navigationController.viewControllers.index(of: viewController) , index > 0 {
                edgeInsetHeight = -WhisperView.Dimensions.height
                performControllerMove(navigationController.viewControllers[Int(index) - 1])
                break
            }
        }
    }
}
