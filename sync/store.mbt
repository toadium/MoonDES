///|
/// FIFO 物品仓库
///
/// 泛型物品仓库，支持生产者-消费者模式。`put` 投递物品，
/// `get` 取出物品。仓库空时 `get` 阻塞等待，有等待消费者时
/// `put` 直接投递。物品按 FIFO 顺序取出。
///
/// 与 `Container` 的区别：Container 管理连续量（液位），
/// Store 管理离散物品（消息、任务、产品）。
///
/// # Example
/// ```mbt check
/// test {
///   let store : Store[Int] = new_store()
///   store.put(42)
///   store.put(99)
///   inspect(store.size(), content="2")
///   let log : Array[Int] = []
///   store.get(fn(item) { log.push(item) })
///   assert_eq(log[0], 42)
/// }
/// ```
pub(all) struct Store[T] {
  items : Array[T]
  consumers : Array[(T) -> Unit]
}

///|
/// 创建 FIFO 物品仓库
pub fn[T] new_store() -> Store[T] {
  { items: [], consumers: [] }
}

///|
/// 投递物品
///
/// 若有等待消费者，直接投递给队首消费者；否则存入仓库。
pub fn[T] Store::put(self : Store[T], item : T) -> Unit {
  if self.consumers.length() > 0 {
    let consumer = self.consumers.remove(0)
    consumer(item)
  } else {
    self.items.push(item)
  }
}

///|
/// 取出物品
///
/// 若仓库有物品，立即取出并执行 `callback`；否则加入等待队列。
pub fn[T] Store::get(self : Store[T], callback : (T) -> Unit) -> Unit {
  if self.items.length() > 0 {
    let item = self.items.remove(0)
    callback(item)
  } else {
    self.consumers.push(callback)
  }
}

///|
/// 仓库中物品数量
pub fn[T] Store::size(self : Store[T]) -> Int {
  self.items.length()
}

///|
/// 仓库是否为空
pub fn[T] Store::is_empty(self : Store[T]) -> Bool {
  self.items.length() == 0
}

///|
/// 等待消费者数量
pub fn[T] Store::consumer_count(self : Store[T]) -> Int {
  self.consumers.length()
}

///|
/// 清空仓库
pub fn[T] Store::clear(self : Store[T]) -> Unit {
  self.items.clear()
  self.consumers.clear()
}

// ---------------------------------------------------------------------------
// PriorityStore — 优先级物品仓库
// ---------------------------------------------------------------------------

///|
/// 优先级物品包装
pub(all) struct PriorityItem[T] {
  item : T
  priority : Int
} derive(Debug)

///|
/// 优先级物品仓库
///
/// 泛型优先级仓库，物品按优先级排序取出（优先级数值越小越先取出）。
/// `put` 投递物品时指定优先级，`get` 取出最高优先级物品。
/// 仓库空时 `get` 阻塞等待。
///
/// # Example
/// ```mbt check
/// test {
///   let store : PriorityStore[String] = new_priority_store()
///   store.put("low", priority=10)
///   store.put("high", priority=1)
///   store.put("mid", priority=5)
///   let log : Array[String] = []
///   store.get(fn(item) { log.push(item) })
///   store.get(fn(item) { log.push(item) })
///   store.get(fn(item) { log.push(item) })
///   assert_eq(log[0], "high")
///   assert_eq(log[1], "mid")
///   assert_eq(log[2], "low")
/// }
/// ```
pub(all) struct PriorityStore[T] {
  items : Array[PriorityItem[T]]
  consumers : Array[(T) -> Unit]
}

///|
/// 创建优先级物品仓库
pub fn[T] new_priority_store() -> PriorityStore[T] {
  { items: [], consumers: [] }
}

///|
/// 投递物品（指定优先级）
///
/// 若有等待消费者，直接投递给队首消费者；否则按优先级插入存储。
/// 优先级数值越小越先取出。
pub fn[T] PriorityStore::put(
  self : PriorityStore[T],
  item : T,
  priority~ : Int,
) -> Unit {
  if self.consumers.length() > 0 {
    let consumer = self.consumers.remove(0)
    consumer(item)
  } else {
    let pi : PriorityItem[T] = { item, priority }
    self._insert_sorted(pi)
  }
}

///|
/// 取出最高优先级物品
///
/// 若仓库有物品，取出优先级最高（数值最小）的物品并执行 `callback`；
/// 否则加入等待队列。
pub fn[T] PriorityStore::get(
  self : PriorityStore[T],
  callback : (T) -> Unit,
) -> Unit {
  if self.items.length() > 0 {
    let pi = self.items.remove(0)
    callback(pi.item)
  } else {
    self.consumers.push(callback)
  }
}

///|
/// 仓库中物品数量
pub fn[T] PriorityStore::size(self : PriorityStore[T]) -> Int {
  self.items.length()
}

///|
/// 仓库是否为空
pub fn[T] PriorityStore::is_empty(self : PriorityStore[T]) -> Bool {
  self.items.length() == 0
}

///|
/// 等待消费者数量
pub fn[T] PriorityStore::consumer_count(self : PriorityStore[T]) -> Int {
  self.consumers.length()
}

///|
/// 清空仓库
pub fn[T] PriorityStore::clear(self : PriorityStore[T]) -> Unit {
  self.items.clear()
  self.consumers.clear()
}

///|
/// 按优先级插入（优先级数值小者排前）
fn[T] PriorityStore::_insert_sorted(
  self : PriorityStore[T],
  pi : PriorityItem[T],
) -> Unit {
  let mut idx = self.items.length()
  for i in 0..<self.items.length() {
    if pi.priority < self.items[i].priority {
      idx = i
      break
    }
  }
  self.items.insert(idx, pi)
}
