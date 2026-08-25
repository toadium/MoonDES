// ===========================================================================
// FilterStore[T] — 过滤物品仓库测试
// ===========================================================================

///|
/// FilterStore：创建后为空
test "filter_store initial empty" {
  let store : FilterStore[Int] = new_filter_store()
  assert_true(store.is_empty())
  assert_eq(store.size(), 0)
  assert_eq(store.consumer_count(), 0)
}

///|
/// FilterStore：基本过滤取出
test "filter_store basic filter" {
  let store : FilterStore[Int] = new_filter_store()
  store.put(10)
  store.put(25)
  store.put(30)
  let log : Array[Int] = []
  // 只取偶数
  store.get(fn(x) { x % 2 == 0 }, fn(item) { log.push(item) })
  assert_eq(log.length(), 1)
  assert_eq(log[0], 10)
  assert_eq(store.size(), 2)
}

///|
/// FilterStore：无匹配物品时阻塞
test "filter_store no match blocks" {
  let store : FilterStore[Int] = new_filter_store()
  store.put(10)
  store.put(30)
  let log : Array[Int] = []
  // 只取奇数，但库存全是偶数
  store.get(fn(x) { x % 2 != 0 }, fn(item) { log.push(item) })
  assert_eq(log.length(), 0)
  assert_eq(store.consumer_count(), 1)
  assert_eq(store.size(), 2)
}

///|
/// FilterStore：put 唤醒匹配的等待消费者
test "filter_store put wakes matching consumer" {
  let store : FilterStore[Int] = new_filter_store()
  let log : Array[Int] = []
  // 先注册一个只取奇数的消费者
  store.get(fn(x) { x % 2 != 0 }, fn(item) { log.push(item) })
  assert_eq(store.consumer_count(), 1)
  // put 偶数 — 不匹配，入库
  store.put(10)
  assert_eq(store.consumer_count(), 1)
  assert_eq(store.size(), 1)
  // put 奇数 — 匹配，直接投递
  store.put(25)
  assert_eq(store.consumer_count(), 0)
  assert_eq(log.length(), 1)
  assert_eq(log[0], 25)
}

///|
/// FilterStore：多消费者不同 filter
test "filter_store multiple consumers different filters" {
  let store : FilterStore[Int] = new_filter_store()
  let log : Array[String] = []
  // 消费者1：只取 > 100
  store.get(fn(x) { x > 100 }, fn(item) { log.push("big:\{item}") })
  // 消费者2：只取 < 50
  store.get(fn(x) { x < 50 }, fn(item) { log.push("small:\{item}") })
  // put 25 — 匹配消费者2
  store.put(25)
  assert_eq(log[0], "small:25")
  // put 200 — 匹配消费者1
  store.put(200)
  assert_eq(log[1], "big:200")
  assert_eq(store.consumer_count(), 0)
}

///|
/// FilterStore：put 匹配第一个等待消费者（FIFO）
test "filter_store put matches first consumer" {
  let store : FilterStore[Int] = new_filter_store()
  let log : Array[Int] = []
  // 两个消费者都接受任何物品
  store.get(fn(_x) { true }, fn(item) { log.push(item * 10) })
  store.get(fn(_x) { true }, fn(item) { log.push(item * 100) })
  // put 匹配第一个消费者
  store.put(5)
  assert_eq(log[0], 50)
  assert_eq(store.consumer_count(), 1)
}

///|
/// FilterStore：泛型支持 String
test "filter_store string type" {
  let store : FilterStore[String] = new_filter_store()
  store.put("apple")
  store.put("banana")
  store.put("cherry")
  let log : Array[String] = []
  // 只取以 'b' 开头
  store.get(fn(s) { s[0] == 'b' }, fn(item) { log.push(item) })
  assert_eq(log[0], "banana")
  assert_eq(store.size(), 2)
}

///|
/// FilterStore：get 取出后库存中剩余物品仍可过滤
test "filter_store sequential gets" {
  let store : FilterStore[Int] = new_filter_store()
  store.put(1)
  store.put(2)
  store.put(3)
  store.put(4)
  let log : Array[Int] = []
  // 取偶数
  store.get(fn(x) { x % 2 == 0 }, fn(item) { log.push(item) })
  store.get(fn(x) { x % 2 == 0 }, fn(item) { log.push(item) })
  assert_eq(log.length(), 2)
  assert_eq(log[0], 2)
  assert_eq(log[1], 4)
  assert_eq(store.size(), 2)
}

///|
/// FilterStore：clear 清空
test "filter_store clear" {
  let store : FilterStore[Int] = new_filter_store()
  store.put(1)
  store.put(2)
  store.get(fn(_x) { true }, fn(_item) { () })
  store.clear()
  assert_eq(store.size(), 0)
  assert_eq(store.consumer_count(), 0)
}

///|
/// FilterStore：全部匹配的 filter（等价于普通 Store）
test "filter_store always_true behaves like store" {
  let store : FilterStore[Int] = new_filter_store()
  store.put(1)
  store.put(2)
  store.put(3)
  let log : Array[Int] = []
  store.get(fn(_x) { true }, fn(item) { log.push(item) })
  store.get(fn(_x) { true }, fn(item) { log.push(item) })
  store.get(fn(_x) { true }, fn(item) { log.push(item) })
  assert_eq(log[0], 1)
  assert_eq(log[1], 2)
  assert_eq(log[2], 3)
}

///|
/// FilterStore：空仓库 get 阻塞
test "filter_store empty get blocks" {
  let store : FilterStore[Int] = new_filter_store()
  let log : Array[Int] = []
  store.get(fn(_x) { true }, fn(item) { log.push(item) })
  assert_eq(store.consumer_count(), 1)
  store.put(42)
  assert_eq(store.consumer_count(), 0)
  assert_eq(log[0], 42)
}
