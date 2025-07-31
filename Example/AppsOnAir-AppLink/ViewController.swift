import UIKit
import AppsOnAir_AppLink

class ViewController: UIViewController {
    let appsOnAirLinkService = AppLinkService.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the button
        let createLinkButton = UIButton(type: .system)
        createLinkButton.setTitle("Create Link", for: .normal)
        createLinkButton.setTitleColor(.white, for: .normal)
        createLinkButton.backgroundColor = .systemBlue
        createLinkButton.layer.cornerRadius = 10
        createLinkButton.translatesAutoresizingMaskIntoConstraints = false
        createLinkButton.addTarget(self, action: #selector(createLinkTapped), for: .touchUpInside)

        // Add button to the view
        view.addSubview(createLinkButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            createLinkButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createLinkButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            createLinkButton.widthAnchor.constraint(equalToConstant: 200),
            createLinkButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc func createLinkTapped() {
        
        //help to get referral information 
        appsOnAirLinkService.getReferralDetails { referralLinkInfo in
            //write code for handle referral link information
        }
        
        //help to set social meta
        let socialMeta = ["imageUrl":"https://image.png","title":"link title","description":"link description"]
        
        //help to create appLink
        // <urlPrefix> shouldn't contain http or https
        appsOnAirLinkService.createAppLink(url: "https://appsonair.com", name: "AppsOnAir", urlPrefix: "YOUR_DOMAIN_NAME",shortId: "LINK_ID",socialMeta: socialMeta, isOpenInBrowserApple: false,isOpenInIosApp: true,iosFallbackUrl: "https://appstore.com") { linkInfo in
            //write code for handle create link
        }
    }
}

