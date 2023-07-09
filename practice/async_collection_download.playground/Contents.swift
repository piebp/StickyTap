extension UIImage {
    
    func scaledDown(into size:CGSize) -> UIImage {
        var (targetWidth, targetHeight) = (self.size.width, self.size.height)
        var (scaleW, scaleH) = (1 as CGFloat, 1 as CGFloat)
        if targetWidth > size.width {
            scaleW = size.width/targetWidth
        }
        if targetHeight > size.height {
            scaleH = size.height/targetHeight
        }
        let scale = min(scaleW,scaleH)
        targetWidth *= scale; targetHeight *= scale
        let sz = CGSize(width: targetWidth, height: targetHeight)
        return UIGraphicsImageRenderer(size:sz).image { _ in
            self.draw(in:CGRect(origin:.zero, size:sz))
        }
    }
}

class RootTrainingController: UIViewController,
                              UICollectionViewDataSource,
                              UICollectionViewDelegate,
                              UICollectionViewDataSourcePrefetching,
                              CollectionPresenterProtocol {
    
    var dataProvider: DataProvider!
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 100, height: 100)
        let collection = UICollectionView(frame: .zero,
                                          collectionViewLayout: layout)
        return collection
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.register(CollectionCellWithImage.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let viewBounds = view.bounds
        collectionView.bounds = viewBounds.inset(by: view.safeAreaInsets)
        collectionView.center = view.center
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataProvider.getNumberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return dataProvider.getNumberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dataItem = dataProvider.getItem(at: indexPath)
        if dataItem.image == nil {
            self.collectionView(collectionView, prefetchItemsAt: [indexPath])
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CollectionCellWithImage else {
            return UICollectionViewCell()
        }
        cell.setData(dataItem)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        dataProvider.fetchData(for: indexPaths)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        dataProvider.releaseImages(for: [indexPath])
    }
    
    func update(at indexPath: IndexPath) {
        OperationQueue.main.addOperation {
            self.collectionView.reloadItems(at: [indexPath])
        }
    }
}

class CollectionCellWithImage: UICollectionViewCell {
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.bounds = contentView.bounds
        imageView.center = CGPoint(x: contentView.bounds.width / 2,
                                   y: contentView.bounds.height / 2)
    }
    
    func setData(_ item: PresentingItem) {
        imageView.image = item.image ?? UIImage(named: "downloading")
    }
}

class PresentingItem {
    
    var url: String? = nil
    var text: String? = nil
    var image: UIImage? = nil
    var taskId: Int? = nil
    
    init(url: String) {
        self.url = url
    }
}

final class NetworkDataProvider: DataProvider, NetworkTaskResponder {
    
    weak var view: CollectionPresenterProtocol?
    
    private let filestoreQueue = DispatchQueue(label: "com.pie.filestore")
    private let networkQueue = OperationQueue()
    private lazy var networkSession: URLSession = {
        return URLSession(configuration: .default,
                          delegate: NetworkTaskDelegate(self),
                          delegateQueue: networkQueue)
    }()
    
    let carUrl = "https://images.ctfassets.net/yadj1kx9rmg0/wtrHxeu3zEoEce2MokCSi/cf6f68efdcf625fdc060607df0f3baef/quwowooybuqbl6ntboz3.jpg"
    
    lazy var items: [PresentingItem] = [
        PresentingItem(url: carUrl), PresentingItem(url: carUrl),
        PresentingItem(url: carUrl),  PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl),
            PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl), PresentingItem(url: carUrl)
    ]
    
    func getNumberOfSections() -> Int {
        return 1
    }
    
    func getNumberOfItems(in section: Int) -> Int {
        return items.count
    }
    
    func getItem(at indexPath: IndexPath) -> PresentingItem {
        return items[indexPath.item]
    }
    
    func fetchData(for indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = items[indexPath.item]
            guard let urlString = item.url,
                  let url = URL(string: urlString) else {
                continue
            }
            guard item.image == nil, item.taskId == nil else {
                continue
            }
            // check if it has been already downloaded
            if let fileURL = getURL(for: item),
               FileManager.default.fileExists(atPath: fileURL.relativePath) {
                read(from: fileURL) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    self.receivedFromFilestore(for: indexPath, with: result)
                }
                return
            }
            let dataTask = networkSession.dataTask(with: url)
            item.taskId = dataTask.taskIdentifier
            dataTask.resume()
        }
    }
    
    func received(_ data: Data, with taskId: Int?) {
        let firstIndex = items.firstIndex {
            $0.taskId == taskId
        }
        if let itemIndex = firstIndex {
            let item = items[itemIndex]
            item.taskId = nil
            let image = UIImage(data: data)?.scaledDown(into: CGSize(width: 100, height: 100))
            item.image = image
            if let imageToSave = image,
               let fileURL = getURL(for: item) {
                write(image: imageToSave, to: fileURL)
            }
            view?.update(at: IndexPath(item: itemIndex, section: 0))
        }
    }
    
    private func getURL(for item: PresentingItem) -> URL? {
        guard let urlString = item.url,
              let url = URL(string: urlString) else {
            return nil
        }
        let name = "quwowooybuqbl6ntboz3.jpg"//url.relativePath
        let fileURL = self.getDocumentsDirectory().appendingPathComponent(name)
        return fileURL
    }
    
    private func receivedFromFilestore(for indexPath: IndexPath, with result: Result<Data, Error>) {
        switch result {
        case .success(let data):
            let item = self.items[indexPath.item]
            item.image = UIImage(data: data)
            self.view?.update(at: IndexPath(item: indexPath.item, section: 0))
        case .failure(let error):
            debugPrint(error.localizedDescription)
        }
    }
    
    func releaseImages(for indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = items[indexPath.item]
            item.image = nil
        }
    }
    
    func read(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        filestoreQueue.async {
            do {
                let data = try Data(contentsOf: url)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func write(image: UIImage, to url: URL) {
        filestoreQueue.async {
            if !FileManager.default.fileExists(atPath: url.relativePath) {
                if let data = image.pngData() {
                    try? data.write(to: url)
                }
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

class NetworkTaskDelegate: NSObject, URLSessionDataDelegate {
    
    private weak var responder: NetworkTaskResponder?
    
    init(_ responder: NetworkTaskResponder) {
        self.responder = responder
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        self.responder?.received(data, with: dataTask.taskIdentifier)
    }
}

protocol NetworkTaskResponder: AnyObject {
    
    func received(_ data: Data, with taskId: Int?)
}

protocol DataProvider {
    
    func getNumberOfSections() -> Int
    func getNumberOfItems(in section: Int) -> Int
    func getItem(at indexPath: IndexPath) -> PresentingItem
    func fetchData(for indexPaths: [IndexPath])
    func releaseImages(for indexPaths: [IndexPath])
}

protocol CollectionPresenterProtocol: AnyObject {
    
    func update(at indexPath: IndexPath)
}
