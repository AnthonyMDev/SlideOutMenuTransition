//
//  SlideOutMenuTransition.swift
//  SlideOutMenuTransition
//
//  Created by Anthony Miller on 7/25/17.
//
import UIKit

open class SlideOutMenuTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    public enum Width {
        case constant(Int)
        case percentOfParent(CGFloat)
    }
    
    public enum Anchor {
        case left, right
    }
    
    public enum Style {
        case plain, underneath, over
    }
    
    /// The duration in seconds that the transition should take to complete.
    /// Defaults to `0.4` seconds.
    public var duration: TimeInterval = 0.4
    
    // TODO: Implement
    public let menuWidth: Width = .percentOfParent(0.8)
    
    // TODO: Implement
    public let anchor: Anchor = .right
    
    // TODO: Implement
    public let style: Style = .underneath
    
    // TODO: Implement
    public let tapToDismiss: Bool = true
    
    // TODO: Implement
    public let swipeToDismiss: Bool = true
    
    private var tapToDismissGesture: UITapGestureRecognizer?
    private var swipeToDismissGesture: UISwipeGestureRecognizer?
    
    private var disabledSubviews: [UIView] = []
    
    private var hideMenuConstraint: NSLayoutConstraint?
    private var showMenuConstraint: NSLayoutConstraint?
    
    private var constraints: [NSLayoutConstraint] = []
    
    private var originalPresentingViewTranslatesAutoresizingMaskValue: Bool?
    private var originalPresentedViewTranslatesAutoresizingMaskValue: Bool?
    
    private var originalPresentingLayerMasksToBoundsValue: Bool?
    private var originalPresentingLayerZPosition: CGFloat?
    private var originalPresentingLayerShadowOffset: CGSize?
    private var originalPresentingLayerShadowRadius: CGFloat?
    private var originalPresentingLayerShadowOpacity: Float?
    
    /*
    *  MARK: - UIViewControllerAnimatedTransitioning
    */
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
                return
        }
        
        let containerView = transitionContext.containerView
        
        let isUnwinding = toViewController.presentedViewController == fromViewController
        let isPresenting = !isUnwinding
        
        let presentingController = isPresenting ? fromViewController : toViewController
        let presentedController = isPresenting ? toViewController : fromViewController
        
        containerView.addSubview(presentingController.view)
        containerView.addSubview(presentedController.view)
        
        if isPresenting {
            setUpForPresentation(presentingController: presentingController,
                                 presentedController: presentedController,
                                 containerView: containerView)
        }
        
        containerView.layoutIfNeeded()
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                isPresenting ? self.showMenu() : self.hideMenu()
                
                containerView.setNeedsLayout()
                containerView.layoutIfNeeded()
                
        },
            completion: { finished in
                if isUnwinding {
                    self.cleanUpAfterDismissal(presentingController: presentingController,
                                               presentedController: presentedController)
                    
                    UIApplication.shared.keyWindow?.addSubview(presentingController.view)
                }
                
                transitionContext.completeTransition(finished)
        })
    }
    
    /*
     *  MARK: Set Up Presentation
     */
    
    private func setUpForPresentation(presentingController: UIViewController,
                                          presentedController: UIViewController,
                                          containerView: UIView) {
        disableAutoresizingMasks(presentingView: presentingController.view,
                                 presentedView: presentedController.view)
        
        setUpConstraints(presentingController.view,
                         presentedView: presentedController.view,
                         containerView: containerView)
        
        disableSubviews(presentingController)
        addDismissGestures(presentingController)
        addShadow(presentingController.view)
    }
    
    /*
     *  MARK: Clean Up Dismissal
     */
    
    private func cleanUpAfterDismissal(presentingController: UIViewController,
                                           presentedController: UIViewController) {
        reenableSubviews()
        deactivateConstraints()
        removeDismissGestures(presentingController)
        resetTranslatesAutoresizingMask(presentingView: presentingController.view,
                                        presentedView: presentedController.view)
        removeShadow(presentingController.view)
    }
    
    /*
     *  MARK: Autoresizing Mask
     */
    
    private func disableAutoresizingMasks(presentingView: UIView, presentedView: UIView) {
        originalPresentingViewTranslatesAutoresizingMaskValue = presentingView.translatesAutoresizingMaskIntoConstraints
        originalPresentedViewTranslatesAutoresizingMaskValue = presentedView.translatesAutoresizingMaskIntoConstraints
        
        presentingView.translatesAutoresizingMaskIntoConstraints = false
        presentedView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func resetTranslatesAutoresizingMask(presentingView: UIView, presentedView: UIView) {
        presentingView.translatesAutoresizingMaskIntoConstraints = originalPresentingViewTranslatesAutoresizingMaskValue ?? true
        presentedView.translatesAutoresizingMaskIntoConstraints = originalPresentedViewTranslatesAutoresizingMaskValue ?? true
        
        originalPresentingViewTranslatesAutoresizingMaskValue = nil
        originalPresentedViewTranslatesAutoresizingMaskValue = nil
    }
    
    /*
     *  MARK: Layout Constraints
     */
    
    private func setUpConstraints(_ presentingView: UIView, presentedView: UIView, containerView: UIView) {
        let priority = UILayoutPriority(rawValue: 999)
        
        hideMenuConstraint = NSLayoutConstraint(item: presentedView, attribute: .leading,
                                                relatedBy: .equal,
                                                toItem: containerView, attribute: .trailing,
                                                multiplier: 1.0, constant: 0)
        hideMenuConstraint?.priority = priority
        
        showMenuConstraint = NSLayoutConstraint(item: presentedView, attribute: .trailing,
                                                relatedBy: .equal,
                                                toItem: containerView, attribute: .trailing,
                                                multiplier: 1.0, constant: 0)
        showMenuConstraint?.priority = priority
        
        let presentingWidthConstraint = NSLayoutConstraint(item: presentingView, attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: containerView, attribute: .width,
                                                           multiplier: 1.0, constant: 0.0)
        
        let presentedWidthConstraint = NSLayoutConstraint(item: presentedView, attribute: .width,
                                                          relatedBy: .equal,
                                                          toItem: containerView, attribute: .width,
                                                          multiplier: 0.8, constant: 0.0)
        
        let presentingTopConstraint = NSLayoutConstraint(item: presentingView, attribute: .top,
                                                         relatedBy: .equal,
                                                         toItem: containerView, attribute: .top,
                                                         multiplier: 1.0, constant: 0.0)
        
        let presentingBottomConstraint = NSLayoutConstraint(item: presentingView, attribute: .bottom,
                                                            relatedBy: .equal,
                                                            toItem: containerView, attribute: .bottom,
                                                            multiplier: 1.0, constant: 0.0)
        
        let presentedTopConstraint = NSLayoutConstraint(item: presentedView, attribute: .top,
                                                        relatedBy: .equal,
                                                        toItem: containerView, attribute: .top,
                                                        multiplier: 1.0, constant: 0.0)
        
        
        let presentedBottomConstraint = NSLayoutConstraint(item: presentedView, attribute: .bottom,
                                                           relatedBy: .equal,
                                                           toItem: containerView, attribute: .bottom,
                                                           multiplier: 1.0, constant: 0.0)
        
        let middleConstraint = NSLayoutConstraint(item: presentingView, attribute: .right,
                                                  relatedBy: .equal,
                                                  toItem: presentedView, attribute: .left,
                                                  multiplier: 1.0, constant: 0.0)
        
        constraints = [presentedWidthConstraint, presentingWidthConstraint,
                       presentingTopConstraint, presentingBottomConstraint,
                       presentedTopConstraint, presentedBottomConstraint,
                       middleConstraint]
        
        NSLayoutConstraint.activate(constraints)
        hideMenuConstraint?.isActive = true
    }
    
    private func showMenu() {
        showMenuConstraint?.isActive = true
        hideMenuConstraint?.isActive = false
    }
    
    private func hideMenu() {
        showMenuConstraint?.isActive = false
        hideMenuConstraint?.isActive = true
    }
    
    private func deactivateConstraints() {
        NSLayoutConstraint.deactivate(constraints)
        hideMenuConstraint?.isActive = false
        showMenuConstraint?.isActive = false
        
        constraints = []
        showMenuConstraint = nil
        hideMenuConstraint = nil
    }
    
    /*
     *  MARK: Disable/Enable Subviews
     */
    
    private func disableSubviews(_ controller: UIViewController) {
        for subview in controller.view.subviews where subview.isUserInteractionEnabled {
            disabledSubviews.append(subview)
            subview.isUserInteractionEnabled = false
        }
    }
    
    private func reenableSubviews() {
        for subview in disabledSubviews {
            subview.isUserInteractionEnabled = true
        }
        disabledSubviews = []
    }
    
    /*
     *  MARK: Dismiss Gestures
     */
    
    private func addDismissGestures(_ controller: UIViewController) {
        tapToDismissGesture = UITapGestureRecognizer(target: controller,
                                                     action: #selector(UIViewController.am_dismissSlideOutMenu(_:)))
        controller.view.addGestureRecognizer(tapToDismissGesture!)
        
        swipeToDismissGesture = UISwipeGestureRecognizer(target: controller,
                                                         action: #selector(UIViewController.am_dismissSlideOutMenu(_:)))
        controller.view.addGestureRecognizer(swipeToDismissGesture!)
    }
    
    private func removeDismissGestures(_ controller: UIViewController) {
        if let tapGesture = tapToDismissGesture {
            controller.view.removeGestureRecognizer(tapGesture)
        }
        if let swipeGesture = swipeToDismissGesture {
            controller.view.removeGestureRecognizer(swipeGesture)
        }
        
        tapToDismissGesture = nil
        swipeToDismissGesture = nil
    }
    
    /*
     *  MARK: Add Shadow
     */
    
    private func addShadow(_ presentingView: UIView) {
        originalPresentingLayerMasksToBoundsValue = presentingView.layer.masksToBounds
        originalPresentingLayerZPosition = presentingView.layer.zPosition
        originalPresentingLayerShadowOffset = presentingView.layer.shadowOffset
        originalPresentingLayerShadowRadius = presentingView.layer.shadowRadius
        originalPresentingLayerShadowOpacity = presentingView.layer.shadowOpacity
        
        presentingView.layer.masksToBounds = false
        presentingView.layer.zPosition = 1
        presentingView.layer.shadowOffset = CGSize(width: 10, height: 0)
        presentingView.layer.shadowRadius = 5
        presentingView.layer.shadowOpacity = 0.5
    }
    
    private func removeShadow(_ presentingView: UIView) {
        presentingView.layer.masksToBounds = originalPresentingLayerMasksToBoundsValue ?? false
        presentingView.layer.zPosition = originalPresentingLayerZPosition ?? 0
        presentingView.layer.shadowOffset = originalPresentingLayerShadowOffset ?? CGSize(width: 0.0, height: -3.0)
        presentingView.layer.shadowRadius = originalPresentingLayerShadowRadius ?? 3.0
        presentingView.layer.shadowOpacity = originalPresentingLayerShadowOpacity ?? 0.0
        
        originalPresentingLayerMasksToBoundsValue = nil
        originalPresentingLayerZPosition = nil
        originalPresentingLayerShadowOffset = nil
        originalPresentingLayerShadowRadius = nil
        originalPresentingLayerShadowOpacity = nil
    }
    
    /*
     *  MARK: - UIViewControllerTransitioningDelegate
     */
    
    open func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
}

import ObjectiveC

extension UIViewController {

    private struct SlideOutMenuAssociatedKeys {
        static var SlideOutMenuTransition = "AMSlideOutMenuTransition"
    }
    
    /// The slide out menu transition that will be used to animate the presentation and dismissal of the view controller.
    public var am_slideOutMenuTransition: SlideOutMenuTransition? {
        get {
            return objc_getAssociatedObject(self, &SlideOutMenuAssociatedKeys.SlideOutMenuTransition) as? SlideOutMenuTransition
        }
        set {
            transitioningDelegate = newValue
            modalPresentationStyle = newValue != nil ? .custom : .fullScreen
            objc_setAssociatedObject(self,
                                     &SlideOutMenuAssociatedKeys.SlideOutMenuTransition,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc func am_dismissSlideOutMenu(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    public func am_presentViewController(_ viewController: UIViewController, with slideOutMenuTransition: SlideOutMenuTransition) {
        viewController.am_slideOutMenuTransition = slideOutMenuTransition

        self.present(viewController, animated: true, completion: nil)
    }

}

class SlideOutMenuSegue: UIStoryboardSegue {

    override func perform() {
        self.source.am_presentViewController(self.destination, with: SlideOutMenuTransition())
    }

}
