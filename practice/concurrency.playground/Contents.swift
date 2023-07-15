import Foundation

//Warmup

func implementRaces() {
    let serQueue = DispatchQueue(label: "com.pie")
    
    let concurQueue = DispatchQueue(label: "com.pie.concurrent",
                                    qos: .userInitiated,
                                    attributes: .concurrent)
    
    // race condition
    for _ in 0..<5 {
        concurQueue.async {
            print("🍎")
        }
        concurQueue.async {
            print("🐸")
        }
    }
    
    // no thread races
    for _ in 0..<5 {
        serQueue.async {
            print("🍎")
        }
        serQueue.async {
            print("🐸")
        }
    }
}

func deadlockExample() {
    let concurQueue = DispatchQueue(label: "com.pie.concurrent",
                                    qos: .userInitiated,
                                    attributes: .concurrent)
    
    DispatchQueue.main.async {
        print("OK")
    }
    
    concurQueue.async {
        DispatchQueue.main.sync {
            print("Also ok")
        }
    }
// page 1107 - author used DispatchQueue.main.sync to preserve resources from being cleared
//    concurQueue.sync {
//        DispatchQueue.main.sync {
//            print("Nothing will be printed")
//        }
//    }
}

// Groups - recognize when all tasks are finished

func groupExample() {
    let group = DispatchGroup()
    group.enter()
    let queue1 = DispatchQueue(label: "queue1")
    let queue2 = DispatchQueue(label: "queue2")
    queue1.async {
        print("Task1 completed")
        group.leave()
    }
    group.enter()
    queue2.async {
        print("Task2 completed")
        group.leave()
    }
    group.enter()
    DispatchQueue.global(qos: .default).async {
        print("Task3 completed")
        group.leave()
    }
    let workItem = DispatchWorkItem {
        print("all tasks completed")
    }
    group.notify(queue: .main, work: workItem)
}

//dispatchPrecondition(condition: .onQueue(.main))

// Semaphores - control amount of threads having an access to shared resource

func semaphores() {
    let semaphore = DispatchSemaphore(value: 4)
    let queue = DispatchQueue(label: "sema", attributes: .concurrent)
    let group = DispatchGroup()
    for i in 0...10 {
        queue.async(group: group) {
            defer { semaphore.signal() }
            semaphore.wait()
            print("start \(i)")
            Thread.sleep(forTimeInterval: 3)
            print("finish \(i)")
        }
    }
}

func semaphoresWithGroups() {
    let semaphore = DispatchSemaphore(value: 4)
    let queue = DispatchQueue(label: "sema", attributes: .concurrent)
    let group = DispatchGroup()
    for i in 0...10 {
        queue.async {
            defer {
                group.leave()
                semaphore.signal()
            }
            semaphore.wait()
            group.enter()
            print("start \(i)")
            Thread.sleep(forTimeInterval: 3)
            print("finish \(i)")
        }
    }
    
    group.notify(queue: .main) {
        print("All tasks completed")
    }
}

func raceConditions() {
    
    //actual for lazy vars
    class SerialProperty {
        private let threadSafeCountQueue = DispatchQueue(label: "...", attributes: .concurrent) //if serial then no need barrier
        private var _count = 0
        public var count: Int {
          get {
            return threadSafeCountQueue.sync { _count }
            }
          set {
              //Если нужно записать переменную - заблокировать очередь и дождаться завершения всех задач. Выполнить текущую задачу (пока остальные заблокированы), затем разблокировать очередь.
              threadSafeCountQueue.async(flags: .barrier) { [unowned self] in
                  self._count = newValue
              }
            }
        }
    }
}

func priorityInversion() {
    //queue with a lower qos given with higher system priority that a queue with higher qos
    let high = DispatchQueue.global(qos: .userInteractive)
    let medium = DispatchQueue.global(qos: .userInitiated)
    let low = DispatchQueue.global(qos: .background)
    let semaphore = DispatchSemaphore(value: 1)
    high.async {
        // Wait 2 seconds just to be sure all the other tasks have enqueued
        Thread.sleep(forTimeInterval: 2)
        semaphore.wait()
        defer { semaphore.signal() }
        print("High priority task is now running")
    }
    for i in 1 ... 10 {
        medium.async {
            let waitTime = Double(exactly: arc4random_uniform(7))!
            print("Running medium task \(i)")
            Thread.sleep(forTimeInterval: waitTime)
        }
    }
    low.async {
        semaphore.wait()
        defer { semaphore.signal() }
        print("Running long, lowest priority task")
        Thread.sleep(forTimeInterval: 5)
    }
}


//The case shows that even if queue is going to be released, quqeued tasks will be completed anyway. It doesn't depend on deadline time.
func just() {
    class Worker {
        let queue = DispatchQueue(label: "sema", attributes: .concurrent)
        
        func doWork(_ task: @escaping () -> Void) {
            queue.asyncAfter(deadline: .now() + 4, execute: task)
        }
    }
    
    var object = NSObject()
    let worker = Worker()
    worker.doWork { [weak object, weak worker] in
        print("1")
        print("\(object?.description ?? "no object")")
        Thread.sleep(forTimeInterval: 1)
        worker?.doWork {
            print("2")
        }
        DispatchQueue.main.sync {
            print("3")
        }
    }
//    queue.sync { [weak object] in
//        print("2")
//        print("\(object?.description ?? "no object")")
//    }
    //thread can call first async block before object release!
}

//You can wrap up a unit of work, or task, and execute it sometime in the future, and then easily submit that unit of work more than once.
func blockOperationCase() {
    //operations have states isready, isexxecuting, iscancelled, isfinished
    
    // block operations can manage multiple tasks and finish when all passed tasks are completed like a group
    let sampleOperations = BlockOperation()
    for text in ["one", "two", "three"] {
        sampleOperations.addExecutionBlock {
            print(text)
        }
    }
    
    sampleOperations.completionBlock = {
        print("all tasks copleted")
    }
    
    //runs concurrently
    sampleOperations.start()
}

func operationQueues() {
    
    class MyOperation: Operation {
        
        override func start() {
            super.start()
            print("started")
        }
        
        override func main() {
            super.main()
            print("main")
        }
    }
    
    // op qu allows pass ready ops, closure and array of ops
    let opQueue = OperationQueue()
    opQueue.qualityOfService = .utility
    opQueue.maxConcurrentOperationCount = 1 // serial
    opQueue.maxConcurrentOperationCount = 2
    
    let operation = MyOperation()
    opQueue.addOperations([operation], waitUntilFinished: false)
}

func asyncOperation() {
    // if operation performs async task (e g networking) then need to notify the opertion when task is finished
    // state props are not settable but operation applies kvo
    
    class AsyncOperation: Operation {
        enum State: String {
           case ready, executing, finished
            
           fileprivate var keyPath: String {
             return "is\(rawValue.capitalized)"
           }
       }
        
        var state = State.ready {
            willSet {
                willChangeValue(forKey: newValue.keyPath)
                willChangeValue(forKey: state.keyPath)
            }
            didSet {
                didChangeValue(forKey: oldValue.keyPath)
                didChangeValue(forKey: state.keyPath)
            }
        }
        
        override var isReady: Bool {
          return super.isReady && state == .ready
        }
        
        override var isExecuting: Bool {
          return state == .executing
        }
        
        override var isFinished: Bool {
          return state == .finished
        }
        
        override var isAsynchronous: Bool {
            return true
        }
        
        override func start() {
          main()
          state = .executing
        }
    }
    
    class MockAsyncOperation: AsyncOperation {
        
        override func main() {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else {
                    return
                }
                defer { self.state = .finished }
                Thread.sleep(forTimeInterval: 3)
                print("job completed")
            }
        }
    }
    
    let operation = MockAsyncOperation()
    operation.start()
}


