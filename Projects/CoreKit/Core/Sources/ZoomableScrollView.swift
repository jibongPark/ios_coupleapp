import SwiftUI

public struct ZoomableScrollView<Content: View>: View {
  let content: Content
  public init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  public var body: some View {
    ZoomableScrollViewImpl(content: content)
  }
}

fileprivate struct ZoomableScrollViewImpl<Content: View>: UIViewControllerRepresentable {
    let content: Content
    
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController(coordinator: context.coordinator)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content))
    }
    
    func updateUIViewController(_ viewController: ViewController, context: Context) {
        viewController.update(content: self.content)
    }
    
    // MARK: - ViewController
    
    class ViewController: UIViewController, UIScrollViewDelegate {
        let coordinator: Coordinator
        let scrollView = UIScrollView()
        
        private var hostedView: UIView { coordinator.hostingController.view! }
        
        private var contentSizeConstraints: [NSLayoutConstraint] = [] {
            willSet { NSLayoutConstraint.deactivate(contentSizeConstraints) }
            didSet { NSLayoutConstraint.activate(contentSizeConstraints) }
        }
        
        required init?(coder: NSCoder) { fatalError() }
        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
            self.view = scrollView
            
            scrollView.delegate = self
            scrollView.maximumZoomScale = 10
            scrollView.minimumZoomScale = 1
            scrollView.bouncesZoom = false
            scrollView.bounces = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.clipsToBounds = false
            
            let hostedView = coordinator.hostingController.view!
            hostedView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(hostedView)
            NSLayoutConstraint.activate([
                hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            ])
            
        }
        
        func update(content: Content) {
            coordinator.hostingController.rootView = content
            scrollView.setNeedsUpdateConstraints()
        }
        
        func handleDoubleTap() {
            scrollView.setZoomScale(scrollView.zoomScale >= 1 ? scrollView.minimumZoomScale : 1, animated: true)
        }
        
        override func updateViewConstraints() {
            super.updateViewConstraints()
            let hostedContentSize = coordinator.hostingController.sizeThatFits(in: view.bounds.size)
            contentSizeConstraints = [
                hostedView.widthAnchor.constraint(equalToConstant: hostedContentSize.width),
                hostedView.heightAnchor.constraint(equalToConstant: hostedContentSize.height),
            ]
        }
        
        override func viewDidAppear(_ animated: Bool) {
            scrollView.zoom(to: hostedView.bounds, animated: false)
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            let hostedContentSize = coordinator.hostingController.sizeThatFits(in: view.bounds.size)
            scrollView.minimumZoomScale = min(
                scrollView.bounds.width / hostedContentSize.width,
                scrollView.bounds.height / hostedContentSize.height)
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // For some reason this is needed in both didZoom and layoutSubviews, thanks to https://medium.com/@ssamadgh/designing-apps-with-scroll-views-part-i-8a7a44a5adf7
            // Sometimes this seems to work (view animates size and position simultaneously from current position to center) and sometimes it does not (position snaps to center immediately, size change animates)
            //      self.scrollView
        }
        
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            //      coordinator.animateAlongsideTransition { [self] context in
            //        scrollView.zoom(to: hostedView.bounds, animated: false)
            //      }
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostedView
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
    }
}
