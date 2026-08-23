// ===========================================================================
// Store[T] — FIFO 物品仓库测试
// ===========================================================================

///|
/// Store：创建后为空
test "store initial empty" {
  let store : Store[Int] = new_store()
  assert_true(store.is_empty())
  assert_eq(store.size(), 0)
  assert_eq(store.consumer_count(), 0)
}

///|
/// Store：put 和 get 基本操作
test "store put get basic" {
  let store : Store[Int] = new_store()
  store.put(42)
  store.put(99)
  assert_eq(store.size(), 2)
  assert_false(store.is_empty())
  let log : Array[Int] = []
  store.get(fn(item) { log.push(item) })
  assert_eq(log[0], 42)
  assert_eq(store.size(), 1)
}

///|
/// Store：FIFO 顺序
test "store fifo order" {
  let store : Store[Int] = new_store()
  store.put(1)
  store.put(2)
  store.put(3)
  let log : Array[Int] = []
  store.get(fn(item) { log.push(item) })
  store.get(fn(item) { log.push(item) })
  store.get(fn(item) { log.push(item) })
  assert_eq(log[0], 1)
  assert_eq(log[1], 2)
  assert_eq(log[2], 3)
}

///|
/// Store：空仓库 get 阻塞（消费者排队）
test "store get blocks when empty" {
  let store : Store[Int] = new_store()
  let log : Array[Int] = []
  store.get(fn(item) { log.push(item) })
  assert_eq(store.consumer_count(), 1)
  // put 后直接投递给等待消费者
  store.put(77)
  assert_eq(store.consumer_count(), 0)
  assert_eq(log[0], 77)
  assert_eq(store.size(), 0)
}

///|
/// Store：多消费者排队
test "store multiple consumers" {
  let store : Store[Int] = new_store()
  let log : Array[Int] = []
  store.get(fn(item) { log.push(item * 10) })
  store.get(fn(item) { log.push(item * 100) })
  assert_eq(store.consumer_count(), 2)
  store.put(3)
  store.put(5)
  assert_eq(log[0], 30)
  assert_eq(log[1], 500)
}

///|
/// Store：put 有消费者时直接投递不入库
test "store put to waiting consumer" {
  let store : Store[String] = new_store()
  let log : Array[String] = []
  store.get(fn(item) { log.push(item) })
  store.put("hello")
  assert_eq(store.size(), 0)
  assert_eq(log[0], "hello")
}

///|
/// Store：泛型支持 String
test "store string type" {
  let store : Store[String] = new_store()
  store.put("a")
  store.put("b")
  let log : Array[String] = []
  store.get(fn(item) { log.push(item) })
  store.get(fn(item) { log.push(item) })
  assert_eq(log[0], "a")
  assert_eq(log[1], "b")
}

///|
/// Store：clear 清空
test "store clear" {
  let store : Store[Int] = new_store()
  store.put(1)
  store.put(2)
  let _ = store.get(fn(_item) { () })
  store.clear()
  assert_eq(store.size(), 0)
  assert_eq(store.consumer_count(), 0)
}

///|
/// Store：交替 put/get
test "store alternating" {
  let store : Store[Int] = new_store()
  let log : Array[Int] = []
  store.put(1)
  store.get(fn(item) { log.push(item) })
  store.put(2)
  store.get(fn(item) { log.push(item) })
  store.put(3)
  store.get(fn(item) { log.push(item) })
  assert_eq(log[0], 1)
  assert_eq(log[1], 2)
  assert_eq(log[2], 3)
}

// ===========================================================================
// PriorityStore[T] — 优先级物品仓库测试
// ===========================================================================

///|
/// PriorityStore：创建后为空
test "priority store initial empty" {
  let store : PriorityStore[Int] = new_priority_store()
  assert_true(store.is_empty())
  assert_eq(store.size(), 0)
}

///|
/// PriorityStore：按优先级取出
test "priority store order" {
  let store : PriorityStore[String] = new_priority_store()
  store.put("low", priority=10)
  store.put("high", priority=1)
  store.put("mid", priority=5)
  let log : Array[String] = []
  store.get(fn(item) { log.push(item) })
  store.get(fn(item) { log.push(item) })
  store.get(fn(item) { log.push(item) })
  assert_eq(log[0], "high")
  assert_eq(log[1], "mid")
  assert_eq(log[2], "low")
}

///|
/// PriorityStore：相同优先级按 FIFO
test "priority store same priority fifo" {
  let store : PriorityStore[Int] = new_priority_store()
  store.put(1, priority=5)
  store.put(2, priority=5)
  store.put(3, priority=5)
  let log : Array[Int] = []
  store.get(fn(item) { log.push(item) })
  store.get(fn(item) { log.push(item) })
  store.get(fn(item) { log.push(item) })
  assert_eq(log[0], 1)
  assert_eq(log[1], 2)
  assert_eq(log[2], 3)
}

///|
/// PriorityStore：空仓库 get 阻塞
test "priority store get blocks when empty" {
  let store : PriorityStore[Int] = new_priority_store()
  let log : Array[Int] = []
  store.get(fn(item) { log.push(item) })
  assert_eq(store.consumer_count(), 1)
  store.put(42, priority=1)
  assert_eq(store.consumer_count(), 0)
  assert_eq(log[0], 42)
}

///|
/// PriorityStore：put 有消费者时直接投递
test "priority store put to waiting consumer" {
  let store : PriorityStore[String] = new_priority_store()
  let log : Array[String] = []
  store.get(fn(item) { log.push(item) })
  store.put("urgent", priority=1)
  assert_eq(store.size(), 0)
  assert_eq(log[0], "urgent")
}

///|
/// PriorityStore：混合优先级
test "priority store mixed priorities" {
  let store : PriorityStore[Int] = new_priority_store()
  store.put(10, priority=3)
  store.put(20, priority=1)
  store.put(30, priority=2)
  store.put(40, priority=1)
  let log : Array[Int] = []
  for _ in 0..<4 {
    store.get(fn(item) { log.push(item) })
  }
  // priority 1: 20, 40 (FIFO), then 2: 30, then 3: 10
  assert_eq(log[0], 20)
  assert_eq(log[1], 40)
  assert_eq(log[2], 30)
  assert_eq(log[3], 10)
}

///|
/// PriorityStore：clear
test "priority store clear" {
  let store : PriorityStore[Int] = new_priority_store()
  store.put(1, priority=1)
  store.put(2, priority=2)
  store.clear()
  assert_eq(store.size(), 0)
  assert_eq(store.consumer_count(), 0)
}

///|
/// PriorityStore：单物品
test "priority store single item" {
  let store : PriorityStore[Double] = new_priority_store()
  store.put(3.14, priority=0)
  let log : Array[Double] = []
  store.get(fn(item) { log.push(item) })
  assert_eq(log[0], 3.14)
  assert_true(store.is_empty())
}
