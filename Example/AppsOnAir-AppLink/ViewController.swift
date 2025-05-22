import UIKit
import AppsOnAir_AppLink

class ViewController: UIViewController {
    let appsOnAirLinkService = AppLinkService.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        appsOnAirLinkService.createAppLink(url: "", name: "", urlPrefix: "") { linkInfo in
            //write code for handle create link
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

