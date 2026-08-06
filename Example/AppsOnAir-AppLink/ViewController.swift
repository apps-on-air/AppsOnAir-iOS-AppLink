import AppsOnAir_AppLink
import UIKit

class ViewController: UIViewController {
    let appLinkService = AppLinkService.shared
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
            createLinkButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    @objc func createLinkTapped() {

        //Help to get attribution information
        appLinkService.getAttributionInfo { attributionInfo in
            //Write code for handle attribution info
        }

        //Help to get referral information
        appLinkService.getReferralInfo { referralInfo in
            //Write code for handle referral info
        }
        appLinkService.getReferralDetails { referralInfo in
            //Write code for handle referral info
        }

        //help to set social meta
        let socialMeta = [
            "imageUrl": "https://image.png", "title": "link title",
            "description": "link description",
        ]

        //help to set AppsFlyer attribution params
        let appsFlyer: [String: Any] = [
            "channel": "appsonair",
            "campaignId": "01",
            "campaign": "test",
            "subs": ["sub1", "sub2", "sub3", "sub4", "sub5"],
            "metaTitle": "metaTitle",
            "metaDescription": "metaDescription",
        ]

        //help to create appLink
        // <urlPrefix> shouldn't contain http or https
        appLinkService.createAppLink(
            url: "https://appsonair.com", name: "AppsOnAir",
            urlPrefix: "YOUR_DOMAIN_NAME", shortId: "LINK_ID",
            socialMeta: socialMeta, isOpenInBrowserApple: false, isOpenInIosApp: true,
            iosFallbackUrl: "https://appstore.com", appsFlyer: appsFlyer, attributionTtl: 3600
        ) { linkInfo in
            //write code for handle create link
        }
    }
}
