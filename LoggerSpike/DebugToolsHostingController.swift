//
//  DebugToolsHostingController.swift
//  LoggerSpike
//
//  Created by Cong Le on 31/08/2024.
//

import SwiftUI
import UIKit

class DebugToolsHostingController: UIHostingController<OverlayButtonsView> {
    
    required init?(coder aDecoder: NSCoder) {
        let viewModel = DebugToolsViewModel()
        let overlayView = OverlayButtonsView(viewModel: viewModel)
        super.init(coder: aDecoder, rootView: overlayView)
    }

    override init(rootView: OverlayButtonsView) {
        super.init(rootView: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension UIViewController {
    func addDebugTools() {
        let viewModel = DebugToolsViewModel()
        let debugToolsController = DebugToolsHostingController(rootView: OverlayButtonsView(viewModel: viewModel))
        
        self.addChild(debugToolsController)
        self.view.addSubview(debugToolsController.view)
        
        debugToolsController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            debugToolsController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            debugToolsController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            debugToolsController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            debugToolsController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        debugToolsController.didMove(toParent: self)
    }
}
