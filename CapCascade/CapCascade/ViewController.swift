
import UIKit
import SpriteKit
import Alamofire
import miyrcu

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)
        
        let jsoei = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        jsoei!.view.tag = 79
        jsoei?.view.frame = UIScreen.main.bounds
        view.addSubview(jsoei!.view)

        let sceneExtent = DimensionalReckoner.reckonSceneExtent()
        let vestibule = VestibuleScene(size: sceneExtent)
        vestibule.scaleMode = .resizeFill
        skView.presentScene(vestibule)
        
        let epoom = NetworkReachabilityManager()
        epoom?.startListening { state in
            switch state {
            case .reachable(_):
                let asdi = GlowVeilView()
                asdi.addSubview(UIImageView())
                
                epoom?.stopListening()
            case .notReachable:
                break
            case .unknown:
                break
            }
        }
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}

