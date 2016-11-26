import UIKit

@objc(HYPPagesControllerDelegate) public protocol PagesControllerDelegate {

  func pageViewController(_ pageViewController: UIPageViewController, setViewController viewController: UIViewController, atPage page: Int)
}

@objc(HYPPagesController) open class PagesController: UIPageViewController {

  struct Dimensions {
    static let bottomLineHeight: CGFloat = 1.0
    static let bottomLineSideMargin: CGFloat = 40.0
    static let bottomLineBottomMargin: CGFloat = 36.0
  }

  open var startPage = 0
  open var setNavigationTitle = true

  open var enableSwipe = true {
    didSet {
      toggle()
    }
  }

  open var showBottomLine = false {
    didSet {
      bottomLineView.isHidden = !showBottomLine
    }
  }

  open var showPageControl = true

  internal(set) open lazy var pages = Array<UIViewController>()
    
  open var pagesCount: Int {
    return pages.count
  }

  open fileprivate(set) var currentIndex = 0

  open weak var pagesDelegate: PagesControllerDelegate?

  open fileprivate(set) lazy var bottomLineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.white
    view.alpha = 0.4
    view.isHidden = true
    return view
    }()

  open fileprivate(set) var pageControl: UIPageControl?

  public convenience init(_ pages: [UIViewController],
    transitionStyle: UIPageViewControllerTransitionStyle = .scroll,
    navigationOrientation: UIPageViewControllerNavigationOrientation = .horizontal,
    options: [String : AnyObject]? = nil) {
      self.init(transitionStyle: transitionStyle,
        navigationOrientation: navigationOrientation,
        options: options)

      add(pages)
  }

  open override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self

    view.addSubview(bottomLineView)
    addConstraints()
    view.bringSubview(toFront: bottomLineView)
    goTo(startPage)
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    for subview in view.subviews {
      if subview is UIPageControl {
        pageControl = subview as? UIPageControl
      }
    }
  }
}

// MARK: Public methods
extension PagesController {

  open func goTo(_ index: Int) {
    if index >= 0 && index < pages.count {
      let direction: UIPageViewControllerNavigationDirection = (index > currentIndex) ? .forward : .reverse
      let viewController = pages[index]
      currentIndex = index
      setViewControllers([viewController],
        direction: direction,
        animated: true,
        completion: { [unowned self] finished in
          self.pagesDelegate?.pageViewController(self,
            setViewController: viewController,
            atPage: self.currentIndex)
        })
      if setNavigationTitle {
        title = viewController.title
      }
    }
  }

  open func moveForward() {
    goTo(currentIndex + 1)
  }

  open func moveBack() {
    goTo(currentIndex - 1)
  }

  open func add(_ viewControllers: [UIViewController]) {
    for viewController in viewControllers {
      addViewController(viewController)
    }
  }
}

// MARK: UIPageViewControllerDataSource

extension PagesController : UIPageViewControllerDataSource {

  open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    let index = prevIndex(viewControllerIndex(viewController))
    return pages.at(index)
  }

  open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    let index: Int? = nextIndex(viewControllerIndex(viewController))
    return pages.at(index)
  }

  open func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return showPageControl ? pages.count : 0
  }

  open func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    return showPageControl ? currentIndex : 0
  }
}

// MARK: UIPageViewControllerDelegate

extension PagesController : UIPageViewControllerDelegate {

  open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
    previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if completed {
      if let viewController = pageViewController.viewControllers?.last,
        let index = viewControllerIndex(viewController) {
          currentIndex = index

          if setNavigationTitle {
            title = viewController.title
          }

          if let pageControl = pageControl {
            pageControl.currentPage = currentIndex
          }

          pagesDelegate?.pageViewController(self, setViewController: pages[currentIndex], atPage: currentIndex)
      }
    }
  }
}

// MARK: Private methods

extension PagesController {

  func viewControllerIndex(_ viewController: UIViewController) -> Int? {
    return pages.index(of: viewController)
  }

  fileprivate func toggle() {
    for subview in view.subviews {
      if let subview = subview as? UIScrollView {
        subview.isScrollEnabled = enableSwipe
        break
      }
    }
  }

  fileprivate func addViewController(_ viewController: UIViewController) {
    pages.append(viewController)

    if pages.count == 1 {
      setViewControllers([viewController],
        direction: .forward,
        animated: true,
        completion: { [unowned self] finished in
          self.pagesDelegate?.pageViewController(self,
            setViewController: viewController,
            atPage: self.currentIndex)
        })
      if setNavigationTitle {
        title = viewController.title
      }
    }
  }

  fileprivate func addConstraints() {
    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: .bottom,
      relatedBy: .equal, toItem: view, attribute: .bottom,
      multiplier: 1, constant: -Dimensions.bottomLineBottomMargin))

    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: .left,
      relatedBy: .equal, toItem: view, attribute: .left,
      multiplier: 1, constant: Dimensions.bottomLineSideMargin))

    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: .right,
      relatedBy: .equal, toItem: view, attribute: .right,
      multiplier: 1, constant: -Dimensions.bottomLineSideMargin))

    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: .height,
      relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
      multiplier: 1, constant: Dimensions.bottomLineHeight))
  }
}

// MARK: Storyboard

extension PagesController {
  
  public convenience init(_ storyboardIds: [String], storyboard: UIStoryboard = UIStoryboard.Main) {
    let pages = storyboardIds.map(storyboard.instantiateViewController(withIdentifier:))
    self.init(pages)
  }
}

// MARK: StaySorted Additions

extension PagesController {
  
  public var pageWidth:CGFloat {
    return view.bounds.width
  }
  
  public var x:CGFloat {
    return CGFloat(currentIndex - 1) * pageWidth + (scrollView?.contentOffset.x ?? 0)
  }
  
  public var totalProgress:CGFloat {
    return x / (pageWidth * CGFloat(pagesCount - 1))
  }
  
  public var currentViewController:UIViewController? {
    return pages.at(currentIndex)
  }
  
  public var previousViewController:UIViewController? {
    return pages.at(currentIndex - 1)
  }
  
  public var nextViewController:UIViewController? {
    return pages.at(currentIndex + 1)
  }
  
  /// Returns a value between -1...1
  /// Where -1...0 signifies entrances from right of screen
  /// And 0...1 signifies exit towards left of screen
  private func progress(forPage page: Int) -> CGFloat {
    return min(1, max(-1, (x - CGFloat(page) * pageWidth) / pageWidth))
  }
  
  private var progressForPrevious:CGFloat {
    return progress(forPage: currentIndex - 1)
  }
  
  private var progressForCurrent:CGFloat {
    return progress(forPage: currentIndex)
  }
  
  private var progressForNext:CGFloat {
    return progress(forPage: currentIndex + 1)
  }
  
  public func updatePageProgresses() {
    
    if let vc = previousViewController as? InterpolatableViewController {
      vc.interpolate(to: progressForPrevious)
    }
    if let vc = currentViewController as? InterpolatableViewController {
      vc.interpolate(to: progressForCurrent)
    }
    if let vc = nextViewController as? InterpolatableViewController {
      vc.interpolate(to: progressForNext)
    }
    
  }
  
  public var scrollView:UIScrollView? {
    for view in view.subviews {
      if let view = view as? UIScrollView {
        return view
      }
    }
    return nil
  }
  
}

public protocol InterpolatableViewController: class {
  
  /// Percent value should be between -1...1
  func interpolate(to progress:CGFloat)
  
}
