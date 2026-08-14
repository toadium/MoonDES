///|
/// 资源类型
pub(all) enum ResourceKind {
  Exclusive // 独占式（如泵站机组）
  Capacity(Int) // 共享容量（如管网输水限额）
  Preemptive // 优先级抢占（如调度通道）
} derive(Debug, Eq)

///|
/// 资源申请请求
pub(all) struct ResourceRequest {
  process_id : @core.ProcessId
  priority : Int
  callback : () -> Unit
  on_preempt : () -> Unit
}

///|
/// 通用资源管理
///
/// 内置独占式、共享容量、优先级抢占三类资源模型，
/// 自动实现资源申请、排队等待、释放、队列排序。
/// Preemptive 资源支持高优先级进程抢占低优先级持有者。
pub(all) struct Resource {
  name : String
  kind : ResourceKind
  mut capacity : Int
  mut in_use : Int
  // 等待队列：按优先级排序
  wait_queue : Array[ResourceRequest]
  // Preemptive 资源的当前持有者（用于抢占）
  mut holder : ResourceRequest?
}

///|
/// 创建独占式资源（容量为 1）
pub fn new_exclusive(name~ : String) -> Resource {
  {
    name,
    kind: Exclusive,
    capacity: 1,
    in_use: 0,
    wait_queue: [],
    holder: None,
  }
}

///|
/// 创建共享容量资源
pub fn new_capacity(name~ : String, capacity~ : Int) -> Resource {
  {
    name,
    kind: Capacity(capacity),
    capacity,
    in_use: 0,
    wait_queue: [],
    holder: None,
  }
}

///|
/// 创建优先级抢占资源
pub fn new_preemptive(name~ : String) -> Resource {
  {
    name,
    kind: Preemptive,
    capacity: 1,
    in_use: 0,
    wait_queue: [],
    holder: None,
  }
}

///|
/// 请求资源：如果可用则立即分配，否则加入等待队列
///
/// 对于 Preemptive 资源，若新请求优先级高于当前持有者，则抢占之：
/// 调用被抢占者的 `on_preempt` 回调，将其重新入队，新请求立即获取资源。
///
/// 返回 true 表示立即获取，false 表示排队等待
pub fn Resource::request(
  self : Resource,
  pid~ : @core.ProcessId,
  priority? : Int = 0,
  callback~ : () -> Unit,
  on_preempt? : () -> Unit = fn() { () },
) -> Bool {
  let req : ResourceRequest = {
    process_id: pid,
    priority,
    callback,
    on_preempt,
  }
  if self.in_use < self.capacity {
    // 资源可用，直接分配
    self.in_use = self.in_use + 1
    if self.kind is Preemptive {
      self.holder = Some(req)
    }
    callback()
    true
  } else if self.kind is Preemptive {
    // Preemptive 资源已满，检查是否可以抢占
    match self.holder {
      Some(holder) =>
        if req.priority < holder.priority {
          // 抢占成功：通知旧持有者，重新入队，新请求获取资源
          (holder.on_preempt)()
          self._insert_sorted(holder)
          self.holder = Some(req)
          callback()
          true
        } else {
          // 优先级不够，排队等待
          self._insert_sorted(req)
          false
        }
      None => {
        // 异常状态（in_use >= capacity 但无 holder），直接分配
        self.in_use = self.in_use + 1
        self.holder = Some(req)
        callback()
        true
      }
    }
  } else {
    // 非抢占资源，排队等待
    self._insert_sorted(req)
    false
  }
}

///|
/// 释放资源：如果有等待进程则唤醒优先级最高的
pub fn Resource::release(self : Resource) -> Unit {
  if self.in_use > 0 {
    self.in_use = self.in_use - 1
  }
  // Preemptive 资源释放后清空 holder
  if self.kind is Preemptive && self.in_use == 0 {
    self.holder = None
  }
  // 唤醒等待队列中的下一个进程
  if self.wait_queue.length() > 0 && self.in_use < self.capacity {
    let req = self.wait_queue.remove(0)
    self.in_use = self.in_use + 1
    if self.kind is Preemptive {
      self.holder = Some(req)
    }
    (req.callback)()
  }
}

///|
/// 当前使用量
pub fn Resource::in_use_count(self : Resource) -> Int {
  self.in_use
}

///|
/// 等待队列长度
pub fn Resource::queue_length(self : Resource) -> Int {
  self.wait_queue.length()
}

///|
/// 资源是否可用
pub fn Resource::is_available(self : Resource) -> Bool {
  self.in_use < self.capacity
}

///|
/// 按优先级插入等待队列（优先级数值小者排前）
fn Resource::_insert_sorted(self : Resource, req : ResourceRequest) -> Unit {
  let mut idx = self.wait_queue.length()
  for i in 0..<self.wait_queue.length() {
    if req.priority < self.wait_queue[i].priority {
      idx = i
      break
    }
  }
  self.wait_queue.insert(idx, req)
}
