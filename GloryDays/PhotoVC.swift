//
//  PhotoVC.swift
//  GloryDays
//
//  Created by James Rochabrun on 12/9/16.
//  Copyright © 2016 James Rochabrun. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech
import CoreSpotlight
import MobileCoreServices

private let reuseIdentifier = "photoCell"

class PhotoVC: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, UISearchBarDelegate {
    
    var memories: [URL] =  []
    var filteredMemories: [URL] = []
    var currentMemory: URL!
    var audioRecorder: AVAudioRecorder?
    var audioPlayer : AVAudioPlayer?
    var recordingURL : URL!
    var searchQuery: CSSearchQuery?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recordingURL =  getDocumentsDirectory().appendingPathComponent("memory-recording.m4a")
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .camera, target: self, action: #selector(self.addImagePressed))

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkForGrantedPermissions()
    }

    func checkForGrantedPermissions() {
        
        let photoAuth: Bool = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuth: Bool = AVAudioSession.sharedInstance().recordPermission() == .granted
        let speechAuth: Bool = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized: Bool = photoAuth && recordingAuth && speechAuth
        
        if !authorized {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "showTerms") {
                navigationController?.present(vc, animated: true)
            }
        }
    }
    
    func loadMemories() {
        
        self.memories.removeAll()
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }
        
        for file in files {
            let fileName = file.lastPathComponent
            
            if fileName.hasSuffix(".thumb") {
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                let memoryPath =  getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
        self.filteredMemories = self.memories
        //empezamos por 1 por la seccion 0 esta la barra de busqueda el hedaerView ocupa una secci´øn
        collectionView?.reloadSections(IndexSet(integer: 1))
        
    }
    
    func getDocumentsDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    func addImagePressed() {
        
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.addNewMemory(image: image)
            self.loadMemories()

            dismiss(animated: true)
        }
    }
    
    func addNewMemory(image: UIImage) {
        
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        let imageName = "\(memoryName).jpg"
        let thumbName = "\(memoryName).thumb"
        
        do {
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            if let jpegData = UIImageJPEGRepresentation(image,80) {
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbail = resizeImage(image, to: 200) {
                
                let thumbPath = getDocumentsDirectory().appendingPathComponent(thumbName)
                if let jpegData = UIImageJPEGRepresentation(thumbail, 80) {
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
            
        } catch {
            print("wirted in disk failed")
        }
    }
    
    func resizeImage(_ image:UIImage, to width:CGFloat) -> UIImage? {
        
        let scaleFactor = width / image.size.width
        let height = image.size.height * scaleFactor
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width:width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        
        if section == 0 {
            return 0
        } else {
            return self.filteredMemories.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        // Configure the cell
        let memory = self.filteredMemories[indexPath.row]
        let memoryName = self.thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: memoryName)
        cell.imageView.image = image
        
        if cell.gestureRecognizers == nil {
            
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.cellLongPressed))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 4.0
            cell.layer.cornerRadius = 10
        }
        
        return cell
    }
    
    func cellLongPressed(sender: UILongPressGestureRecognizer)  {
        
        if sender.state == .began {
            
            let cell = sender.view as! PhotoCell
            if let index = collectionView?.indexPath(for: cell) {
                self.currentMemory = self.filteredMemories[index.row]
                self.startRecordingMemory()
            }
            
        } else if sender.state == .ended {
            self.finishRecordingmemory(success: true)
        }
    }
    
    func startRecordingMemory() {
        
        self.audioPlayer?.stop()
        
        collectionView?.backgroundColor = #colorLiteral(red: 0.8878455758, green: 0.4013058543, blue: 0.2430705428, alpha: 1)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with:.defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let recordinSettings = [AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                                    AVSampleRateKey : 44100,
                                    AVNumberOfChannelsKey : 2,
                                    AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue]
            
            self.audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordinSettings)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.record()
            
            
        } catch let error {
            print(error.localizedDescription)
            self.finishRecordingmemory(success: false)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if !flag {
            self.finishRecordingmemory(success: false)
        }
    }
    
    func finishRecordingmemory(success: Bool) {
        
        collectionView?.backgroundColor = #colorLiteral(red: 0.5091350079, green: 0.9878887534, blue: 0.8044660687, alpha: 1)
        self.audioRecorder?.stop()
        
        if success {
            do {
            
                let memoryAdioURL = self.currentMemory.appendingPathExtension("m4a")
                let fileManager = FileManager.default
            
                if fileManager.fileExists(atPath: memoryAdioURL.path) {
                    try fileManager.removeItem(at: memoryAdioURL)
                }
                try fileManager.moveItem(at: recordingURL, to: memoryAdioURL)
                
                self.transcribeAudioToText(memory: self.currentMemory)
                
            } catch let error{
                print(error.localizedDescription)
            }
        }
    }
    
    func transcribeAudioToText(memory : URL) {
        
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
            
            guard let result = result else {
                print("Ha habido el siguiente error : \(error)")
                return
            }
            
            if result.isFinal {
                
                let text = result.bestTranscription.formattedString
                
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    //for search functionality
                    self.indexMemory(memory: memory, text: text)
                } catch {
                    print("Ha habido un error al guardar la traducción")
                }
            }
        })
    }
    
    ///spotlight THATS IT!
    func indexMemory(memory: URL, text: String) {
        
        let attributeSet =  CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "glory memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)
        
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.james", attributeSet: attributeSet)
        item.expirationDate = Date.distantFuture
     
        CSSearchableIndex.default().indexSearchableItems([item]) { (error) in
            
            if let error = error {
                print("there was an eror \(error)")
            } else {
                print("index succesfull: \(text)")
            }
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: 0, height: 50)
        } else {
            return CGSize.zero
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let memory = self.filteredMemories[indexPath.row]
        let fileManager = FileManager.default
        
        do {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            
            if fileManager.fileExists(atPath: audioName.path) {
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
            }
            
            if fileManager.fileExists(atPath: transcriptionName.path){
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        } catch {
            print("error to load the audio")
        }
    }
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }

    //MARK :: searchbar
    
    func filterMemories(text: String) {
        
        guard text.characters.count > 0 else {
            self.filteredMemories = self.memories
            
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer: 1))
            }
            return
        }
        
        var allItems: [CSSearchableItem] = []
        
        self.searchQuery?.cancel()
        
        let queryString = "contentDescription == \"*\(text)*\"c"
        self.searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        
        self.searchQuery?.foundItemsHandler = { items in
            allItems.append(contentsOf: items)
        }
        
        self.searchQuery?.completionHandler = { error in
            
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: allItems)
            }
        }
        self.searchQuery?.start()
    }
    
    func activateFilter(matches: [CSSearchableItem]){
        
        self.filteredMemories = matches.map { item in
            let uniqueID = item.uniqueIdentifier
            let url = URL(fileURLWithPath: uniqueID)
            return url
        }
        
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer: 1))
        }        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterMemories(text: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
