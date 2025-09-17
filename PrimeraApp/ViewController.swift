import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
    
    // Player
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    // Views
    let videoContainer = UIView()
    
    // Buttons
    let btnLaPaz = UIButton(type: .system)
    let btnSantaCruz = UIButton(type: .system)
    let btnRQP = UIButton(type: .system)
    let btnRedes = UIButton(type: .system)
    
    // Extra controls
    let playPauseButton = UIButton(type: .system)
    let fullscreenButton = UIButton(type: .system)
    let volumeSlider = UISlider()
    
    // URLs
    let urlLaPaz = "https://d2qsan2ut81n2k.cloudfront.net/live/20446f64-67d8-4100-8c4b-20a759a8e919/ts:abr.m3u8"
    let urlSanta = "https://d2qsan2ut81n2k.cloudfront.net/live/3338960e-86ca-4c50-a567-913c663b26fc/ts:abr.m3u8"
    let urlRQP = "https://d3kdr6se8micr4.cloudfront.net/index.m3u8"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupViews()
        setupPlayer()
    }
    
    func setupViews() {
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoContainer)
        
        // Buttons styling
        let buttons = [btnLaPaz, btnSantaCruz, btnRQP, btnRedes]
        let titles = ["EN VIVO LA PAZ", "EN VIVO SANTA CRUZ", "RQP EN VIVO", "REDES DIGITALES"]
        for (b, t) in zip(buttons, titles) {
            b.setTitle(t, for: .normal)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            b.layer.cornerRadius = 6
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.lightGray.cgColor
            b.translatesAutoresizingMaskIntoConstraints = false
            b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        // Actions
        btnLaPaz.addTarget(self, action: #selector(playLaPaz), for: .touchUpInside)
        btnSantaCruz.addTarget(self, action: #selector(playSanta), for: .touchUpInside)
        btnRQP.addTarget(self, action: #selector(playRQP), for: .touchUpInside)
        btnRedes.addTarget(self, action: #selector(playRedes), for: .touchUpInside)
        
        // Use stack views to get 2x2 grid
        let topRow = UIStackView(arrangedSubviews: [btnLaPaz, btnSantaCruz])
        topRow.axis = .horizontal
        topRow.distribution = .fillEqually
        topRow.spacing = 12
        topRow.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomRow = UIStackView(arrangedSubviews: [btnRQP, btnRedes])
        bottomRow.axis = .horizontal
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 12
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        
        let vStack = UIStackView(arrangedSubviews: [topRow, bottomRow])
        vStack.axis = .vertical
        vStack.distribution = .fillEqually
        vStack.spacing = 12
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(vStack)
        
        // Extra controls container
        let controlsStack = UIStackView(arrangedSubviews: [playPauseButton, fullscreenButton, volumeSlider])
        controlsStack.axis = .horizontal
        controlsStack.spacing = 12
        controlsStack.alignment = .center
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsStack)
        
        // Layout constraints
        let videoTopConstraint = NSLayoutConstraint(item: videoContainer, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0)
        let videoLeading = NSLayoutConstraint(item: videoContainer, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0)
        let videoTrailing = NSLayoutConstraint(item: videoContainer, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0)
        let videoHeight = NSLayoutConstraint(item: videoContainer, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.8, constant: 0)
        
        view.addConstraints([videoTopConstraint, videoLeading, videoTrailing, videoHeight])
        
        // vStack constraints - place below videoContainer with padding
        let vstackTop = NSLayoutConstraint(item: vStack, attribute: .top, relatedBy: .equal, toItem: videoContainer, attribute: .bottom, multiplier: 1.0, constant: 12)
        let vstackLeading = NSLayoutConstraint(item: vStack, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 16)
        let vstackTrailing = NSLayoutConstraint(item: vStack, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -16)
        let vstackBottom = NSLayoutConstraint(item: vStack, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: controlsStack, attribute: .top, multiplier: 1.0, constant: -12)
        view.addConstraints([vstackTop, vstackLeading, vstackTrailing, vstackBottom])
        
        // Controls constraints
        let controlsTop = NSLayoutConstraint(item: controlsStack, attribute: .top, relatedBy: .equal, toItem: vStack, attribute: .bottom, multiplier: 1.0, constant: 12)
        let controlsLeading = NSLayoutConstraint(item: controlsStack, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 16)
        let controlsTrailing = NSLayoutConstraint(item: controlsStack, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -16)
        view.addConstraints([controlsTop, controlsLeading, controlsTrailing])
        
        // Configure extra controls
        playPauseButton.setTitle("Pause", for: .normal)
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        fullscreenButton.setTitle("Full", for: .normal)
        fullscreenButton.addTarget(self, action: #selector(toggleFullscreen), for: .touchUpInside)
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = AVAudioSession.sharedInstance().outputVolume
        
        // Add background to video container
        videoContainer.backgroundColor = UIColor.black
        videoContainer.layer.masksToBounds = true
    }
    
    func setupPlayer() {
        // Default: play La Paz stream
        guard let url = URL(string: urlLaPaz) else { return }
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        // CORRECCIÓN: Usar sintaxis completa para Swift 3
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = videoContainer.bounds
        if let pl = playerLayer {
            videoContainer.layer.addSublayer(pl)
        }
        
        videoContainer.addObserver(self, forKeyPath: "bounds", options: [.new, .initial], context: nil)
        
        player?.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds" {
            playerLayer?.frame = videoContainer.bounds
        }
    }
    
    deinit {
        videoContainer.removeObserver(self, forKeyPath: "bounds")
    }
    
    // MARK: - Actions
    @objc func playLaPaz() {
        playURLString(urlLaPaz)
    }
    @objc func playSanta() {
        playURLString(urlSanta)
    }
    @objc func playRQP() {
        playURLString(urlRQP)
    }
    @objc func playRedes() {
        // Play local file 'estudio.mp4' in bundle
        if let path = Bundle.main.path(forResource: "estudio", ofType: "mp4") {
            let localURL = URL(fileURLWithPath: path)
            replacePlayerItem(with: localURL)
        } else {
            showAlert(title: "Archivo no encontrado", message: "Asegúrate de añadir 'estudio.mp4' al bundle del proyecto")
        }
    }
    
    func playURLString(_ s: String) {
        guard let u = URL(string: s) else {
            showAlert(title: "URL inválida", message: s)
            return
        }
        replacePlayerItem(with: u)
    }
    
    func replacePlayerItem(with url: URL) {
        let item = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: item)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = videoContainer.bounds
            // CORRECCIÓN: Usar sintaxis completa para Swift 3
            playerLayer?.videoGravity = .resizeAspect
            if let pl = playerLayer {
                videoContainer.layer.addSublayer(pl)
            }
        } else {
            player?.replaceCurrentItem(with: item)
        }
        player?.play()
    }
    
    @objc func togglePlayPause() {
        guard let p = player else { return }
        if p.rate == 0 {
            p.play()
            playPauseButton.setTitle("Pause", for: .normal)
        } else {
            p.pause()
            playPauseButton.setTitle("Play", for: .normal)
        }
    }
    
    @objc func toggleFullscreen() {
        // Simple fullscreen: present a new view controller with the playerLayer moved into it.
        guard let pl = playerLayer else { return }
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.black
        pl.removeFromSuperlayer()
        pl.frame = vc.view.bounds
        // CORRECCIÓN: Usar sintaxis completa para Swift 3
        pl.videoGravity = .resizeAspect
        vc.view.layer.addSublayer(pl)
        // Add a close button
        let close = UIButton(frame: CGRect(x: 20, y: 30, width: 60, height: 30))
        close.setTitle("Cerrar", for: .normal)
        close.addTarget(self, action: #selector(closeFullscreen(_:)), for: .touchUpInside)
        vc.view.addSubview(close)
        present(vc, animated: true, completion: nil)
    }
    
    @objc func closeFullscreen(_ sender: UIButton) {
        // Move playerLayer back to container
        guard let pl = playerLayer else { return }
        pl.removeFromSuperlayer()
        pl.frame = videoContainer.bounds
        videoContainer.layer.addSublayer(pl)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func volumeChanged(_ sender: UISlider) {
        player?.volume = sender.value
    }
    
    func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(a, animated: true, completion: nil)
    }
}
