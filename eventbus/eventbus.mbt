///|
/// 订阅者：持有 ID 和回调
struct Subscriber {
  id : Int
  callback : (String) -> Unit
}

///|
/// 事件总线
///
/// 发布-订阅模式，实现进程间解耦通信。
/// 订阅者通过 `subscribe(topic, callback)` 注册对某个主题的兴趣，
/// 发布者通过 `publish(topic, data)` 向所有订阅者投递消息。
///
/// 订阅返回唯一 ID，可用 `unsubscribe(topic, id)` 取消。
///
/// # Example
/// ```mbt check
/// test {
///   let bus = @eventbus.new_event_bus()
///   let log : Array[String] = []
///   let id = bus.subscribe("sensor", fn(data) { log.push(data) })
///   let count = bus.publish("sensor", "temperature=25")
///   assert_eq(count, 1)
///   assert_eq(log[0], "temperature=25")
///   ignore(bus.unsubscribe("sensor", id))
///   let count2 = bus.publish("sensor", "test")
///   assert_eq(count2, 0)
/// }
/// ```
pub(all) struct EventBus {
  subscribers : Map[String, Array[Subscriber]]
  mut next_id : Int
}

///|
/// 创建事件总线
pub fn new_event_bus() -> EventBus {
  { subscribers: {}, next_id: 1 }
}

///|
/// 订阅主题
///
/// 注册回调 `callback` 到主题 `topic`，返回唯一订阅 ID。
/// 同一主题可有多个订阅者，按注册顺序依次通知。
pub fn EventBus::subscribe(
  self : EventBus,
  topic : String,
  callback : (String) -> Unit,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  match self.subscribers.get(topic) {
    Some(list) => list.push({ id, callback })
    None => self.subscribers[topic] = [{ id, callback }]
  }
  id
}

///|
/// 发布消息
///
/// 向主题 `topic` 的所有订阅者投递消息 `data`，
/// 返回被通知的订阅者数量。
/// 无订阅者时返回 0。
pub fn EventBus::publish(self : EventBus, topic : String, data : String) -> Int {
  match self.subscribers.get(topic) {
    Some(list) => {
      let count = list.length()
      for sub in list {
        (sub.callback)(data)
      }
      count
    }
    None => 0
  }
}

///|
/// 取消订阅
///
/// 移除主题 `topic` 下 ID 为 `id` 的订阅者。
/// 返回 `true` 表示成功移除，`false` 表示未找到。
pub fn EventBus::unsubscribe(self : EventBus, topic : String, id : Int) -> Bool {
  match self.subscribers.get(topic) {
    Some(list) => {
      let mut found = -1
      for i in 0..<list.length() {
        if list[i].id == id {
          found = i
          break
        }
      }
      if found >= 0 {
        ignore(list.remove(found))
        true
      } else {
        false
      }
    }
    None => false
  }
}

///|
/// 订阅者数量
///
/// 返回主题 `topic` 下的订阅者数量。
pub fn EventBus::subscriber_count(self : EventBus, topic : String) -> Int {
  match self.subscribers.get(topic) {
    Some(list) => list.length()
    None => 0
  }
}

///|
/// 所有主题
///
/// 返回当前有订阅者的所有主题列表。
pub fn EventBus::topics(self : EventBus) -> Array[String] {
  let result : Array[String] = []
  for key in self.subscribers.keys() {
    match self.subscribers.get(key) {
      Some(list) => if list.length() > 0 { result.push(key) }
      None => ()
    }
  }
  result
}

///|
/// 清空主题
///
/// 移除主题 `topic` 下的所有订阅者。
pub fn EventBus::clear(self : EventBus, topic : String) -> Unit {
  match self.subscribers.get(topic) {
    Some(list) => list.clear()
    None => ()
  }
}

///|
/// 总订阅数
///
/// 返回所有主题下的订阅者总数。
pub fn EventBus::total_subscribers(self : EventBus) -> Int {
  let mut total = 0
  for key in self.subscribers.keys() {
    match self.subscribers.get(key) {
      Some(list) => total += list.length()
      None => ()
    }
  }
  total
}
