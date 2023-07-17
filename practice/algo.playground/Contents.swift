import UIKit

var greeting = "Hello, playground"

func isPalindromic(_ s: String) -> Bool {
    if s.count == 2 && Set(s).count == 2 {
        return false
    }
    
    return s == String(s.reversed())
}

// Sorting

func bubble() {
    func sortSequence<T>(_ elements: inout Array<T>)  where T: Equatable & Comparable {
        
        var swapped = false
        repeat {
            
            swapped = false
            
            for index in 0..<elements.count - 1 {
                if elements[index] > elements[index + 1] {
                    let temp = elements[index]
                    elements[index] = elements[index + 1]
                    elements[index + 1] = temp
                    swapped = true
                }
            }
            
        } while swapped
    }
    
    var inp = [10, 7, 5, 1, 4, 11]
    sortSequence(&inp)
    assert(inp == [1, 4, 5, 7, 10, 11])
}

func selection() {
        
    func sortSequence<T>(_ elements: inout Array<T>)  where T: Equatable & Comparable {
        
        var sortedCount = 0
        
        while sortedCount < elements.count - 1 {
            
            var minIndex = sortedCount + 1
            for index in (sortedCount + 1)..<elements.count {
                if elements[index] < elements[minIndex] {
                    minIndex = index
                }
            }
            
            var insertIndex = sortedCount + 1
            for index in 0...sortedCount {
                if elements[index] > elements[minIndex] {
                    insertIndex = index
                    break
                }
            }
            
            let temp = elements[insertIndex]
            elements[insertIndex] = elements[minIndex]
            elements[minIndex] = temp
            
            sortedCount += 1
        }
    }
    
    var inp = [10, 7, 5, 1, 4, 11]
    sortSequence(&inp)
    assert(inp == [1, 4, 5, 7, 10, 11])
}

func mergeSort() {

    func sortSequence<T>(_ elements: inout Array<T>)  where T: Equatable & Comparable {
        
      func splitted(_ array: [T]) -> [T] {
          guard array.count > 1 else {
              return array
          }
          let midIndex = array.count / 2
          let splittedLeft = splitted(Array(array[0..<midIndex]))
          let splittedRight = splitted(Array(array[midIndex..<array.count]))
          return merged(splittedLeft, splittedRight)
      }
      
      func merged(_ first: [T], _ second: [T]) -> [T] {
          
          var result = [T]()
          var indexFirst = 0
          var indexSecond = 0
          
          while indexFirst < first.count && indexSecond < second.count {
              
              if first[indexFirst] < second[indexSecond] {
                  result.append(first[indexFirst])
                  indexFirst += 1
                  continue
              }
              
              if second[indexSecond] < first[indexFirst] {
                  result.append(second[indexSecond])
                  indexSecond += 1
                  continue
              }
              
              result.append(first[indexFirst])
              result.append(second[indexSecond])
              indexFirst += 1
              indexSecond += 1
          }
          
          if first.count > 0 {
              let firstSuffixLen = first.count - indexFirst
              result.append(contentsOf: Array(first.suffix(firstSuffixLen)))
          }
         
          if second.count > 0 {
              let secondSuffixLen = second.count - indexSecond
              result.append(contentsOf: Array(second.suffix(secondSuffixLen)))
          }
          
          return result
      }
      
      // [10, 7, 5, 1, 4]
      // split
      // [10, 7] [5, 1, 4]
      // [10] [7] [5] [1, 4]
      // [10] [7] [5] [1] [4]
      // [7, 10] [5] [1, 4]
      // [7, 10] [1, 4, 5]
      // [1, 4, 5, 7, 10]
      elements = splitted(elements)
    }
    
    var inp = [10, 71, 5, 1, 4, 12]

    sortSequence(&inp)
    assert(inp == [1, 4, 5, 10, 12, 71])
}

func radix() {

    func sortSequence(_ array: inout [Int]) {
        // 10, 7171, 5
        // till reach max pow10
        var maxRadix = 1
        for item in array {
           maxRadix = max(maxRadix, findPowerOf(item))
        }
    
        var result = array
        
        for radix in 0...maxRadix - 1 {
            // buckets should be array not dict!
            var buckets: [Int: [Int]] = [:]
            for item in result {
                let powered = (pow(10, radix) as NSDecimalNumber).intValue
                let remainder = (item / powered) % 10
                if buckets[remainder] == nil {
                    buckets[remainder] = [item]
                    continue
                }
                buckets[remainder]?.append(item)
            }
            
            result = buckets.keys.sorted().flatMap {
                return buckets[$0]!
            }
        }
        
        array = result
    }
    
    func findPowerOf(_ value: Int) -> Int {
        var power = 1
        var remainder = value
        while true  {
            let powered = (pow(10, power) as NSDecimalNumber).intValue
            if value / powered == 0 {
                break
            }
            remainder /= powered
            power += 1
        }
        return power
    }
    
    var inp = [10, 7171, 5, 1, 4, 120]
    sortSequence(&inp)
    assert(inp == [1, 4, 5, 10, 120, 7171])
}

// Heap

struct Heap<Element>: CustomStringConvertible where Element: Comparable {
    
    var elements: [Element] = []
    
    var sort: (Element, Element) -> Bool
    
    init(_ elements: [Element],
         _ sort: @escaping (Element, Element) -> Bool) {
        self.elements = elements
        self.sort = sort
    }
    
    func getLeftChildIndex(_ parentIndex: Int) -> Int {
        let index = parentIndex * 2 + 1
        guard index < elements.count else {
            return parentIndex
        }
        return index
    }
    
    func getRightChildIndex(_ parentIndex: Int) -> Int {
        let index = parentIndex * 2 + 2
        guard index < elements.count else {
            return parentIndex
        }
        return index
    }
    
    func getParentIndex(_ childIndex: Int) -> Int {
        guard childIndex > 0 else {
            return childIndex
        }
        return (childIndex - 1) / 2
    }
    
    mutating
    func append(_ element: Element) {
        elements.append(element)
        shakeUp()
    }
    
    mutating
    func shakeUp() {
        guard elements.count > 2 else {
            return
        }
        var candidate = elements.count - 1
        while true {
            let parent = getParentIndex(candidate)
            if parent == candidate {
                break
            }
           
            if sort(elements[candidate], elements[parent]) {
                swapAt(parent, and: candidate)
                candidate = parent
                continue
            }
            break
        }
    }
    
    mutating
    func removeRoot() -> Element? {
        guard !elements.isEmpty else {
            return nil
        }
        
        let root = elements[0]
        if elements.count == 1 {
            elements.removeAll()
            return root
        }
        
        swapAt(0, and: elements.indices.last!)
        elements.removeLast()
        
        shakeDown(from: 0)
        
        return root
    }
    
    mutating
    func makeValid() {
         var currentVisitIndex = 0
         while currentVisitIndex < elements.count {
             while shakeDown(from: currentVisitIndex) {
                 continue
             }
             currentVisitIndex += 1
         }
    }

    func sorted() -> [Element] {
         var heap = Heap(elements, sort)
         for index in heap.elements.indices.reversed() {
             heap.swapAt(index, and: 0)
             heap.shakeDown(from: 0, upTo: index)
         }
         return heap.elements
    }
    
    mutating
    func shakeDown(from index: Int, upTo barrier: Int?=nil) -> Bool {
        guard elements.indices.contains(index) else {
            return false
        }
        
        let left = getLeftChildIndex(index)
        let right = getRightChildIndex(index)
      
        var shaked = false
        if index != left && left < (barrier ?? 1000) && sort(elements[left], elements[index]) {
            swapAt(index, and: left)
            shakeDown(from: left, upTo: barrier)
            shaked = true
        }
        
        if index != right && right < (barrier ?? 1000) && sort(elements[right], elements[index]) {
            swapAt(index, and: right)
            shakeDown(from: right, upTo: barrier)
            shaked = true
        }
        
        return shaked
    }
    
    mutating
    private func swapAt(_ index1: Int, and index2: Int) {
        let temp = elements[index1]
        elements[index1] = elements[index2]
        elements[index2] = temp
    }
    
    var description: String {
        return String(elements.count)
    }
}

func testHeap() {
    var data = Array([1, 2, 3, 4, 5, 6, 7].reversed())
    var heap = Heap(data) {
        $0 > $1
    }
    assert(heap.getLeftChildIndex(2) == 5)
    assert(heap.getRightChildIndex(2) == 6)
    assert(heap.getParentIndex(4) == 1)
    
    assert(heap.removeRoot() == 7)
    assert(heap.elements == [6, 4, 5, 1, 3, 2])
    
    heap.append(9)
    print(heap.elements)
    assert(heap.elements == [9, 4, 6, 1, 3, 2, 5])
    
    data = [8, 3, 6, 1, 2, 5, 4]
    heap = Heap(data) {
        $0 > $1
    }
    heap.append(7)
    // no error cuz bigger elements go to left when shake up
    heap.removeRoot()
    assert(heap.elements == [7, 3, 6, 1, 2, 5, 4])
    
    heap.elements = [6, 12, 2, 26, 8, 18, 21, 9, 5]
    heap.makeValid()
    print(heap.elements)
    assert(heap.sorted() == [2, 5, 6, 8, 9, 12, 18, 21, 26])
}


protocol Queue {
    associatedtype Element
    mutating func enqueue(_ element: Element) -> Bool
    mutating func dequeue() -> Element?
    func peek() -> Element?
    func isEmpty() -> Bool
}

func testPriorityQueue() {

    struct PriorityQueue<Element>: Queue where Element: Comparable {
            
        var heap: Heap<Element>
        
        init(_ elements: [Element], _ sort: @escaping (Element, Element) -> Bool) {
            self.heap = Heap<Element>(elements, sort)
        }
        
        mutating
        func enqueue(_ element: Element) -> Bool {
            heap.append(element)
            return true
        }
        
        mutating
        func dequeue() -> Element? {
            return heap.removeRoot()
        }
        
        func peek() -> Element? {
            return heap.elements.first
        }
        
        func isEmpty() -> Bool {
            heap.elements.isEmpty
        }
    }
        
    let data = [8, 3, 6, 1, 2, 5, 4]
    var queue = PriorityQueue(data, >)
    
    ["d", "d"].joined(separator: <#T##String#>)
    print(queue.dequeue() ?? -1)
}



struct Vertex<T> {
    var index: Int
    var data: T
    
    init(_ index: Int, _ data: T) {
        self.index = index
        self.data = data
    }
}

extension Vertex: Hashable {
    
    public var hashValue: Int {
        return index.hashValue
    }
    
    public static func == (lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.index == rhs.index
    }
}

extension Vertex: CustomStringConvertible {
    
    public var description: String {
        return "(\(index) \(data))"
    }
}

enum EdgeType {
    case directed
    case undirected
}


struct Edge<T>: Comparable {
    var type: EdgeType
    var from: Vertex<T>
    var to: Vertex<T>
    var weight: Int? = nil
    
    static func < (lhs: Edge<T>, rhs: Edge<T>) -> Bool {
        return (lhs.weight ?? 0) < (rhs.weight) ?? 0
    }
}

protocol Graph {
    associatedtype Element
    
    
    mutating func addDirectedEdge(from: Vertex<Element>, to: Vertex<Element>, _ weight: Int?)
    mutating func addUndirectedEdge(from: Vertex<Element>, to: Vertex<Element>, _ weight: Int?)
    mutating func addEdge(type: EdgeType, from: Vertex<Element>, to: Vertex<Element>, _ weight: Int?)
    mutating func remove(_ vertex: Vertex<Element>)
    mutating func append(_ vertex: Vertex<Element>)
}

struct AdjacencyList<Element>: Graph {
    
    var adjacency: [Vertex<Element>: [Edge<Element>]] = [:]
    
    var count: Int {
        return adjacency.keys.count
    }
    
    mutating
    func addDirectedEdge(from: Vertex<Element>, to: Vertex<Element>, _ weight: Int?=nil) {
        addEdge(type: .directed, from: from, to: to, weight)
    }
    
    mutating
    func addUndirectedEdge(from: Vertex<Element>, to: Vertex<Element>, _ weight: Int?=nil) {
        addEdge(type: .undirected, from: from, to: to, weight)
    }
    
    mutating
    func addEdge(type: EdgeType, from: Vertex<Element>, to: Vertex<Element>, _ weight: Int?=nil) {
        guard adjacency.keys.contains(from) && adjacency.keys.contains(to) else {
            return
        }
        let edge = Edge(type: type, from: from, to: to, weight: weight)
        safelyConnect(edge, to: from)
        if type == .undirected {
            safelyConnect(edge, to: to)
        }
    }
    
    func edges(from vertex: Vertex<Element>) -> [Edge<Element>] {
        return adjacency[vertex] ?? []
    }
    
    @discardableResult
    mutating
    func createVertex(_ value: Element) -> Vertex<Element> {
        let index = adjacency.keys.count
        let vertex = Vertex(index, value)
        adjacency[vertex] = []
        return vertex
    }
      
    mutating
    func remove(_ vertex: Vertex<Element>) {
        adjacency[vertex] = nil
    }
    
    mutating
    func append(_ vertex: Vertex<Element>) {
        adjacency[vertex] = []
    }
    
    mutating
    private func safelyConnect(_ edge: Edge<Element>,
                              to vertex: Vertex<Element>) {
        if adjacency[vertex] == nil {
            return
        }
        adjacency[vertex]!.append(edge)
    }
}

extension AdjacencyList: CustomStringConvertible {
    
    public var description: String {
        let strings: [String] = adjacency.keys.map { vertex in
            let edgeStrings = adjacency[vertex]!
            .map {
                if $0.type == .directed {
                    return String($0.from.index)
                }
                if vertex == $0.to {
                    return String($0.from.index)
                }
                return String($0.to.index)
            }
            .joined(separator:" ")
            return "Element \(vertex.index): \(edgeStrings)"
        }
        return "Adjacency list: \n" + strings.joined(separator:"\n")
    }
}

extension AdjacencyList {
    
    func breadthFirstSearch(from vertex: Vertex<Element>) -> [Vertex<Element>] {
        guard adjacency.keys.contains(vertex) else {
            return []
        }
        
        var queue = ArrayQueue<Vertex<Element>>()
        var enqueued = Set<Vertex<Element>>()
        var visited = [Vertex<Element>]()
       
        queue.enqueue(vertex)
        enqueued.insert(vertex)
        
        while let currentVertex = queue.dequeue() {
            // collect neighbors of vertex and put it to queue
            visited.append(currentVertex)
            let edges = edges(from: currentVertex)
            let neighbors: [Vertex<Element>] = edges.map {
                if $0.from == currentVertex {
                    return $0.to
                }
                // undirected case
                return $0.from
            }
            neighbors.forEach {
                if enqueued.contains($0) {
                    return
                }
                queue.enqueue($0)
                enqueued.insert($0)
            }
        }
        
        return visited
    }
}

struct ArrayQueue<Element>: Queue, CustomStringConvertible {
    
    var elements: [Element]
    
    init(_ elements: [Element]=[]) {
        self.elements = elements
    }
    
    mutating func enqueue(_ element: Element) {
        elements.append(element)
    }
    
    @discardableResult
    mutating func dequeue() -> Element? {
        guard !elements.isEmpty else {
            return nil
        }
        return elements.removeFirst()
    }
    
    func peek() -> Element? {
        return elements.first
    }
    
    var description: String {
        return "\(elements)"
    }
}

extension AdjacencyList {
    
    func dijkstraPath(from vertex: Vertex<Element>) -> [Vertex<Element>: (Vertex<Element>, Int)] {
        
        var result: [Vertex<Element>: (Vertex<Element>, Int)] = [:]
        
        var current: Vertex<Element> = vertex
        var previous: Vertex<Element> = vertex
        
        //var edge: Edge<Element>?
        var queue = PriorityQueue<Edge<Element>>([], >)
        
        edges(from: current).forEach {
            queue.enqueue($0)
        }
        
        while let edge = queue.dequeue() {
        
             let weight = (edge.weight ?? 0)
            
            // sum weights
            
            //weight shouldnt be nil
            if result[current] == nil ||
                result[current]!.1 > weight {
                  result[current] = (previous, weight)
            }
            
            previous = current
            current = edge.to
            
            edges(from: current).forEach {
                queue.enqueue($0)
            }
        }
        
        return result
    }
}


func testGraph() {
    var graph = AdjacencyList<String>()
    let vertex1 = Vertex(0, "Zero")
    let vertex2 = Vertex(1, "One")
    let vertex3 = Vertex(2, "Two")
    graph.append(vertex1)
    graph.append(vertex2)
    graph.append(vertex3)
    graph.addDirectedEdge(from: vertex1, to: vertex2, 2)
    graph.addDirectedEdge(from: vertex1, to: vertex3, 1)

    var vertex = graph.createVertex("Three")
    graph.addDirectedEdge(from: vertex2, to: vertex, 3)
    graph.addDirectedEdge(from: vertex, to: vertex3, 2)
    
    /*
    vertex = graph.createVertex("New")
    graph.addUndirectedEdge(from: vertex, to: vertex3)
    
    vertex = graph.createVertex("New")
    graph.addUndirectedEdge(from: vertex, to: vertex2)
    
    vertex = graph.createVertex("New")
    graph.addUndirectedEdge(from: vertex, to: vertex3)
    */
    
    print(graph)
    print(graph.breadthFirstSearch(from: vertex1))
    
    let dPath = graph.dijkstraPath(from: vertex1)
    print(dPath)
    
    var queue = ArrayQueue([1, 2])
    queue.enqueue(4)
    queue.enqueue(5)
    assert(queue.elements == [1, 2, 4, 5])
    queue.dequeue()
    assert(queue.elements == [2, 4, 5])
}
testGraph()
