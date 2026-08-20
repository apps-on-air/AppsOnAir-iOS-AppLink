import AppsOnAir_AppLink
import UIKit

class ViewController: UIViewController {
    let appLinkService = AppLinkService.shared

    private let contentStack = UIStackView()
    private var sectionViews: [ResponseSection: ResponseSectionView] = [:]

    // createAppLink inputs, mirroring the React Native example's form.
    private let nameField = UITextField()
    private let urlField = UITextField()
    private let urlPrefixField = UITextField()
    private let shortIdField = UITextField()
    private let androidFallbackField = UITextField()
    private let iosFallbackField = UITextField()
    private let attributionTtlField = UITextField()
    private let appsFlyerView = UITextView()
    private let openInAndroidAppSwitch = UISwitch()
    private let openInAndroidBrowserSwitch = UISwitch()
    private let openInIosAppSwitch = UISwitch()
    private let openInAppleBrowserSwitch = UISwitch()

    /// The SDK forwards this dictionary to the API untouched, so it is edited as raw JSON rather
    /// than fixed fields — any keys beyond the documented ones are passed through as-is.
    private let defaultAppsFlyerJSON = """
        {
          "channel": "appsonair",
          "campaignId": "01",
          "campaign": "test",
          "subs": ["sub1", "sub2", "sub3", "sub4", "sub5"],
          "metaTitle": "metaTitle",
          "metaDescription": "metaDescription"
        }
        """

    private let loaderOverlay = UIView()
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupTopBar()
        setupContent()
        setupLoaderOverlay()

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // The buttons and fields below still receive their own touches
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)

        NotificationCenter.default.addObserver(
            self, selector: #selector(renderResults),
            name: AppLinkResultStore.didChangeNotification, object: nil)
        renderResults()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    private let topBar = UIView()

    private func setupTopBar() {
        topBar.backgroundColor = Palette.primaryContainer
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        let titleLabel = UILabel()
        titleLabel.text = "AppLink Demo"
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),

            titleLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -12),
        ])
    }

    private func setupContent() {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        scrollView.alwaysBounceVertical = true
        // The scroll view already sits below the top bar, so it must not inset for the safe area
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        addSection(.deepLink)

        addDivider()

        addSection(.deprecatedListener)
        addSection(.deprecatedApi)
        addButton("Get Referral Details (Deprecated)", action: #selector(getReferralDetailsTapped))
        addButton("Get Referral Info (Deprecated)", action: #selector(getReferralInfoTapped))

        addDivider()

        addSection(.attributionListener)
        addSection(.attributionApi)
        addButton("Get Attribution Info", action: #selector(getAttributionInfoTapped))

        addDivider()

        addSectionTitle("Create AppLink")
        addTextField(nameField, label: "Name", text: "AppsOnAir")
        addTextField(urlField, label: "URL", text: "https://appsonair.com")
        // urlPrefix shouldn't contain http or https
        addTextField(urlPrefixField, label: "URL Prefix", text: "")
        addTextField(shortIdField, label: "Short ID", text: "")
        addTextField(androidFallbackField, label: "Android Fallback URL", text: "")
        addTextField(iosFallbackField, label: "iOS Fallback URL", text: "")
        addTextField(
            attributionTtlField, label: "Attribution TTL (seconds)", text: "",
            keyboardType: .numberPad)
        addTextViewField(
            appsFlyerView, label: "AppsFlyer params (JSON, any keys allowed)",
            text: defaultAppsFlyerJSON)

        addSwitchRow(openInAndroidAppSwitch, label: "Open in Android App", isOn: true)
        addSwitchRow(openInAndroidBrowserSwitch, label: "Open in Android Browser", isOn: false)
        addSwitchRow(openInIosAppSwitch, label: "Open in iOS App", isOn: true)
        addSwitchRow(openInAppleBrowserSwitch, label: "Open in iOS Browser", isOn: false)

        addSection(.createLink)
        addButton("Create Link", action: #selector(createLinkTapped))
    }

    private func setupLoaderOverlay() {
        // Semi-transparent background that blocks all touch interactions
        loaderOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        loaderOverlay.isHidden = true
        loaderOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loaderOverlay)

        activityIndicator.color = .blue
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loaderOverlay.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            loaderOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loaderOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loaderOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loaderOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: loaderOverlay.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loaderOverlay.centerYAnchor),
        ])
    }

    private func addSection(_ section: ResponseSection) {
        let sectionView = ResponseSectionView(title: section.title)
        sectionViews[section] = sectionView
        contentStack.addArrangedSubview(sectionView)
    }

    private func addSectionTitle(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 0
        addRow(label, topInset: 12, bottomInset: 4)
    }

    private func addTextField(
        _ field: UITextField, label: String, text: String,
        keyboardType: UIKeyboardType = .default
    ) {
        field.text = text
        field.placeholder = label
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 14)
        field.textColor = .black
        field.keyboardType = keyboardType
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
        addLabeledInput(label: label, input: field)
    }

    private func addTextViewField(_ textView: UITextView, label: String, text: String) {
        textView.text = text
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .black
        // The outer scroll view handles scrolling, so the box grows to fit its content instead
        textView.isScrollEnabled = false
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 6
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        addLabeledInput(label: label, input: textView)
    }

    private func addSwitchRow(_ toggle: UISwitch, label: String, isOn: Bool) {
        toggle.isOn = isOn
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, toggle])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        addRow(stack)
    }

    private func addLabeledInput(label: String, input: UIView) {
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, input])
        stack.axis = .vertical
        stack.spacing = 4
        addRow(stack)
    }

    /// Wraps a view in the 16pt horizontal gutter the sections use.
    private func addRow(_ content: UIView, topInset: CGFloat = 4, bottomInset: CGFloat = 4) {
        content.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: topInset),
            content.bottomAnchor.constraint(
                equalTo: container.bottomAnchor, constant: -bottomInset),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])
        contentStack.addArrangedSubview(container)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func addDivider() {
        let divider = UIView()
        divider.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentStack.addArrangedSubview(divider)
    }

    private func addButton(_ title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Palette.primary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = Palette.buttonSurface
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 2
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        // Buttons are centered while the sections fill the width
        let container = UIView()
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])
        contentStack.addArrangedSubview(container)
    }

    // MARK: - Rendering

    @objc private func renderResults() {
        for (section, sectionView) in sectionViews {
            sectionView.value = AppLinkResultStore.shared[section]
        }
    }

    private func setLoading(_ isLoading: Bool) {
        // `createAppLink` reports back on a background queue
        DispatchQueue.main.async {
            self.loaderOverlay.isHidden = !isLoading
            if isLoading {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }

    // MARK: - Actions

    /// Deprecated, shown here only so its payload can be compared with `getAttributionInfo()`.
    @objc private func getReferralDetailsTapped() {
        appLinkService.getReferralDetails { referralInfo in
            AppLinkResultStore.shared[.deprecatedApi] = responseText(referralInfo)
        }
    }

    /// Deprecated, shown here only so its payload can be compared with `getAttributionInfo()`.
    @objc private func getReferralInfoTapped() {
        appLinkService.getReferralInfo { referralInfo in
            AppLinkResultStore.shared[.deprecatedApi] = responseText(referralInfo)
        }
    }

    //Help to get attribution information
    @objc private func getAttributionInfoTapped() {
        appLinkService.getAttributionInfo { attributionInfo in
            AppLinkResultStore.shared[.attributionApi] = responseText(attributionInfo)
        }
    }

    @objc private func createLinkTapped() {
        dismissKeyboard()

        // Parsed before the call so malformed JSON is reported on its own rather than as an
        // API failure.
        var appsFlyer: [String: Any]?
        let appsFlyerText = (appsFlyerView.text ?? "").trimmingCharacters(
            in: .whitespacesAndNewlines)
        if !appsFlyerText.isEmpty {
            guard let data = appsFlyerText.data(using: .utf8),
                let parsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            else {
                AppLinkResultStore.shared[.createLink] =
                    "Invalid AppsFlyer JSON — fix the JSON and try again."
                return
            }
            appsFlyer = parsed
        }

        setLoading(true)  // Show loader

        //help to set social meta
        let socialMeta = [
            "imageUrl": "https://image.png", "title": "link title",
            "description": "link description",
        ]

        //help to create appLink
        // <urlPrefix> shouldn't contain http or https
        appLinkService.createAppLink(
            url: text(urlField), name: text(nameField),
            urlPrefix: text(urlPrefixField),
            shortId: text(shortIdField).isEmpty ? nil : text(shortIdField),
            socialMeta: socialMeta,
            isOpenInBrowserApple: openInAppleBrowserSwitch.isOn,
            isOpenInIosApp: openInIosAppSwitch.isOn,
            iosFallbackUrl: text(iosFallbackField),
            isOpenInAndroidApp: openInAndroidAppSwitch.isOn,
            isOpenInBrowserAndroid: openInAndroidBrowserSwitch.isOn,
            androidFallbackUrl: text(androidFallbackField),
            appsFlyer: appsFlyer,
            attributionTtl: Int(text(attributionTtlField))
        ) { [weak self] linkInfo in
            print("API response==> \(linkInfo)")
            AppLinkResultStore.shared[.createLink] = responseText(linkInfo)
            self?.setLoading(false)  // Hide loader
        }
    }

    private func text(_ field: UITextField) -> String {
        (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Supporting views

/// Approximates the Material 3 light color scheme used by the Android sample.
private enum Palette {
    static let primary = UIColor(red: 0.40, green: 0.31, blue: 0.64, alpha: 1)
    static let primaryContainer = UIColor(red: 0.92, green: 0.87, blue: 1.00, alpha: 1)
    static let buttonSurface = UIColor(red: 0.97, green: 0.95, blue: 0.98, alpha: 1)
}

/// A titled panel showing the latest response for one part of the SDK.
private final class ResponseSectionView: UIView {
    private let valueView = UITextView()

    var value: String = "" {
        didSet { valueView.text = value.isEmpty ? "No data yet" : value }
    }

    init(title: String) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 14)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0

        // Selectable so the response can be selected and copied off the device
        valueView.isEditable = false
        valueView.isScrollEnabled = false
        valueView.isSelectable = true
        valueView.backgroundColor = .clear
        valueView.textContainerInset = .zero
        valueView.textContainer.lineFragmentPadding = 0
        valueView.font = .systemFont(ofSize: 12)
        valueView.textColor = .black
        valueView.text = "No data yet"

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueView])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
