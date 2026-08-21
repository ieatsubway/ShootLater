@preconcurrency import AVFoundation
import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> CameraCaptureViewController {
        let controller = CameraCaptureViewController()
        controller.onCapture = onCapture
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraCaptureViewController, context: Context) {}
}

final class CameraCaptureViewController: UIViewController, @preconcurrency AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let cameraSession = CameraCaptureSession()
    private var isSessionConfigured = false
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let shutter = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureControls()
        requestAccessAndConfigureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraSession.stop()
    }

    private func requestAccessAndConfigureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            let cameraSession = cameraSession
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    DispatchQueue.main.async {
                        self?.showUnavailableMessage("Camera access is required to capture a spot.")
                    }
                    return
                }
                cameraSession.configure { success in
                    DispatchQueue.main.async {
                        self?.finishSessionConfiguration(succeeded: success)
                    }
                }
            }
        case .denied, .restricted:
            showUnavailableMessage("Camera access is required to capture a spot.")
        @unknown default:
            showUnavailableMessage("Camera is unavailable.")
        }
    }

    private func configureSession() {
        cameraSession.configure { [weak self] success in
            DispatchQueue.main.async {
                self?.finishSessionConfiguration(succeeded: success)
            }
        }
    }

    private func finishSessionConfiguration(succeeded: Bool) {
        guard succeeded else {
            showUnavailableMessage("Camera is unavailable.")
            return
        }

        let preview = AVCaptureVideoPreviewLayer(session: cameraSession.session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
        isSessionConfigured = true
        shutter.isEnabled = true
        statusLabel.isHidden = true
    }

    private func configureControls() {
        shutter.setImage(UIImage(systemName: "circle.inset.filled"), for: .normal)
        shutter.tintColor = .white
        shutter.isEnabled = false
        shutter.setPreferredSymbolConfiguration(.init(pointSize: 72, weight: .regular), forImageIn: .normal)
        shutter.addTarget(self, action: #selector(capture), for: .touchUpInside)
        shutter.accessibilityLabel = "Capture scouting photo"
        shutter.accessibilityIdentifier = "cameraShutterButton"

        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.tintColor = .white
        cancel.addTarget(self, action: #selector(cancelCapture), for: .touchUpInside)
        cancel.accessibilityLabel = "Cancel camera capture"
        cancel.accessibilityIdentifier = "cameraCancelButton"

        statusLabel.textColor = .white
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true
        statusLabel.accessibilityIdentifier = "cameraStatusLabel"

        [shutter, cancel, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            shutter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            cancel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cancel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func capture() {
        guard isSessionConfigured, cameraSession.output.connection(with: .video) != nil else {
            showUnavailableMessage("Camera is unavailable.")
            return
        }
        cameraSession.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    @objc private func cancelCapture() {
        onCancel?()
    }

    private func showUnavailableMessage(_ message: String) {
        shutter.isEnabled = false
        statusLabel.text = message
        statusLabel.isHidden = false
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard
            error == nil,
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else { return }
        DispatchQueue.main.async { [onCapture] in
            onCapture?(image)
        }
    }
}

private final class CameraCaptureSession: @unchecked Sendable {
    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "com.shootlater.camera-session")
    private var isConfigured = false

    func configure(completion: @escaping @Sendable (Bool) -> Void) {
        queue.async { [self] in
            if isConfigured {
                if !session.isRunning {
                    session.startRunning()
                }
                completion(true)
                return
            }

            session.beginConfiguration()
            session.sessionPreset = .photo

            guard
                let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: camera),
                session.canAddInput(input),
                session.canAddOutput(output)
            else {
                session.commitConfiguration()
                completion(false)
                return
            }

            session.addInput(input)
            session.addOutput(output)
            session.commitConfiguration()
            isConfigured = true
            session.startRunning()
            completion(true)
        }
    }

    func stop() {
        queue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }
}
