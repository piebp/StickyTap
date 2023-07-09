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