///|
/// 过滤消费者：持有谓词和回调
struct FilterConsumer[T] {
  filter : (T) -> Bool
  callback : (T) -> Unit
}

///|
/// 过滤物品仓库
///
/// 泛型仓库，消费者通过谓词 `filter` 声明只接收满足条件的物品。
/// `put(item)` 投递物品时，检查等待消费者队列中第一个 filter 匹配的消费者，
/// 直接投递给它；若无匹配消费者，物品入库存放。
/// `get(filter, callback)` 取物品时，先检查库存中第一个满足 filter 的物品，
/// 找到则立即取出；否则加入等待消费者队列。
///
/// 对标 SimPy `FilterStore`。
///
/// # Example
/// ```mbt check
/// test {
///   let store : FilterStore[Int] = new_filter_store()
///   store.put(10)
///   store.put(25)
///   store.put(30)
///   let log : Array[Int] = []
///   // 只取偶数
///   store.get(fn(x) { x % 2 == 0 }, fn(item) { log.push(item) })
///   assert_eq(log[0], 10)
///   assert_eq(store.size(), 2)
/// }
/// ```
pub(all) struct FilterStore[T] {
  items : Array[T]
  consumers : Array[FilterConsumer[T]]
}

///|
/// 创建过滤物品仓库
pub fn[T] new_filter_store() -> FilterStore[T] {
  { items: [], consumers: [] }
}

///|
/// 投递物品
///
/// 检查等待消费者队列，找到第一个 filter 匹配的消费者直接投递；
/// 若无匹配消费者，物品入库存放。
pub fn[T] FilterStore::put(self : FilterStore[T], item : T) -> Unit {
  // 查找第一个匹配的等待消费者
  let mut found_idx = -1
  for i in 0..<self.consumers.length() {
    if (self.consumers[i].filter)(item) {
      found_idx = i
      break
    }
  }
  if found_idx >= 0 {
    let consumer = self.consumers.remove(found_idx)
    (consumer.callback)(item)
  } else {
    self.items.push(item)
  }
}

///|
/// 取出满足条件的物品
///
/// 先检查库存中第一个满足 `filter` 的物品，找到则立即取出；
/// 否则加入等待消费者队列。
pub fn[T] FilterStore::get(
  self : FilterStore[T],
  filter : (T) -> Bool,
  callback : (T) -> Unit,
) -> Unit {
  // 查找库存中第一个匹配的物品
  let mut found_idx = -1
  for i in 0..<self.items.length() {
    if filter(self.items[i]) {
      found_idx = i
      break
    }
  }
  if found_idx >= 0 {
    let item = self.items.remove(found_idx)
    callback(item)
  } else {
    self.consumers.push({ filter, callback })
  }
}

///|
/// 仓库中物品数量
pub fn[T] FilterStore::size(self : FilterStore[T]) -> Int {
  self.items.length()
}

///|
/// 仓库是否为空
pub fn[T] FilterStore::is_empty(self : FilterStore[T]) -> Bool {
  self.items.length() == 0
}

///|
/// 等待消费者数量
pub fn[T] FilterStore::consumer_count(self : FilterStore[T]) -> Int {
  self.consumers.length()
}

///|
/// 清空仓库
pub fn[T] FilterStore::clear(self : FilterStore[T]) -> Unit {
  self.items.clear()
  self.consumers.clear()
}
