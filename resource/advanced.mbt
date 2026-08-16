///|
/// 资源池：管理多个同类资源的集合
///
/// 自动分配空闲资源，适用于多服务器、多通道等场景。
/// 进程请求时自动选择一个空闲资源分配；释放时归还到池中。
pub(all) struct ResourcePool {
  name : String
  resources : Array[Resource]
  // 每个槽位的持有者 pid（-1 表示空闲）
  mut holders : Array[Int]
}

///|
/// 创建资源池（包含 size 个独占式资源）
///
/// # Example
/// ```mbt check
/// test {
///   let pool = @resource.new_pool(name="servers", size=3)
///   inspect(pool.size(), content="3")
///   inspect(pool.available_count(), content="3")
/// }
/// ```
pub fn new_pool(name~ : String, size~ : Int) -> ResourcePool {
  let resources : Array[Resource] = []
  let holders : Array[Int] = []
  for i in 0..<size {
    resources.push(new_exclusive(name="\{name}_\{i}"))
    holders.push(-1)
  }
  { name, resources, holders }
}

///|
/// 请求资源池中任意空闲资源
///
/// 返回 true 表示立即获取，false 表示池满需等待。
/// 获取的资源槽位索引可通过 `pool.holder_slot(pid)` 查询。
pub fn ResourcePool::request(
  self : ResourcePool,
  pid~ : @core.ProcessId,
  callback~ : () -> Unit,
) -> Bool {
  for i in 0..<self.resources.length() {
    if self.holders[i] == -1 {
      self.holders[i] = pid
      let r = self.resources[i]
      ignore(r.request(pid~, callback~))
      return true
    }
  }
  false
}

///|
/// 释放指定进程持有的资源
pub fn ResourcePool::release(
  self : ResourcePool,
  pid~ : @core.ProcessId,
) -> Unit {
  for i in 0..<self.resources.length() {
    if self.holders[i] == pid {
      self.holders[i] = -1
      self.resources[i].release()
      return
    }
  }
}

///|
/// 资源池大小
pub fn ResourcePool::size(self : ResourcePool) -> Int {
  self.resources.length()
}

///|
/// 空闲资源数
pub fn ResourcePool::available_count(self : ResourcePool) -> Int {
  let mut count = 0
  for h in self.holders {
    if h == -1 {
      count += 1
    }
  }
  count
}

///|
/// 查询指定进程持有的资源槽位索引（-1 表示未持有）
pub fn ResourcePool::holder_slot(
  self : ResourcePool,
  pid~ : @core.ProcessId,
) -> Int {
  for i in 0..<self.resources.length() {
    if self.holders[i] == pid {
      return i
    }
  }
  -1
}

///|
/// 可重入资源：同一进程可多次获取同一资源
///
/// 适用于递归调用场景。进程需对应次数的释放才能完全释放资源。
pub(all) struct ReentrantResource {
  name : String
  // 当前持有者 pid（-1 表示空闲）
  mut holder_pid : Int
  // 持有计数（同进程多次获取时累加）
  mut hold_count : Int
  // 等待队列
  wait_queue : Array[(Int, () -> Unit)]
}

///|
/// 创建可重入资源
///
/// # Example
/// ```mbt check
/// test {
///   let r = @resource.new_reentrant(name="lock")
///   inspect(r.is_free(), content="true")
/// }
/// ```
pub fn new_reentrant(name~ : String) -> ReentrantResource {
  { name, holder_pid: -1, hold_count: 0, wait_queue: [] }
}

///|
/// 请求可重入资源
///
/// 如果资源空闲或调用者已是持有者，立即获取并返回 true。
/// 否则排队等待，返回 false。
pub fn ReentrantResource::request(
  self : ReentrantResource,
  pid~ : @core.ProcessId,
  callback~ : () -> Unit,
) -> Bool {
  if self.holder_pid == -1 {
    // 资源空闲，直接获取
    self.holder_pid = pid
    self.hold_count = 1
    callback()
    true
  } else if self.holder_pid == pid {
    // 同进程再次获取，计数加一
    self.hold_count = self.hold_count + 1
    callback()
    true
  } else {
    // 被其他进程持有，排队等待
    self.wait_queue.push((pid, callback))
    false
  }
}

///|
/// 释放可重入资源
///
/// 持有计数减一。当计数归零时完全释放，唤醒下一个等待者。
pub fn ReentrantResource::release(
  self : ReentrantResource,
  pid~ : @core.ProcessId,
) -> Unit {
  if self.holder_pid == pid && self.hold_count > 0 {
    self.hold_count = self.hold_count - 1
    if self.hold_count == 0 {
      self.holder_pid = -1
      // 唤醒下一个等待者
      if self.wait_queue.length() > 0 {
        let (next_pid, next_cb) = self.wait_queue.remove(0)
        self.holder_pid = next_pid
        self.hold_count = 1
        next_cb()
      }
    }
  }
}

///|
/// 查询持有计数
pub fn ReentrantResource::hold_count_of(
  self : ReentrantResource,
  pid~ : @core.ProcessId,
) -> Int {
  if self.holder_pid == pid {
    self.hold_count
  } else {
    0
  }
}

///|
/// 资源是否空闲
pub fn ReentrantResource::is_free(self : ReentrantResource) -> Bool {
  self.holder_pid == -1
}

///|
/// 等待队列长度
pub fn ReentrantResource::queue_length(self : ReentrantResource) -> Int {
  self.wait_queue.length()
}

///|
/// 资源组：将多个资源组合，支持批量获取/释放
///
/// 适用于需要同时占用多个资源的场景（如工序需要机床+工人+工具）。
pub(all) struct ResourceGroup {
  resources : Array[Resource]
  // 每个资源是否被本组占用
  mut acquired : Array[Bool]
}

///|
/// 创建空资源组
pub fn new_group() -> ResourceGroup {
  { resources: [], acquired: [] }
}

///|
/// 添加资源到组
pub fn ResourceGroup::add(self : ResourceGroup, resource : Resource) -> Unit {
  self.resources.push(resource)
  self.acquired.push(false)
}

///|
/// 批量请求组内所有资源
///
/// 如果全部可用则一次性获取，返回 true。
/// 如果任一资源不可用则不获取任何资源，返回 false（原子语义）。
pub fn ResourceGroup::request_all(
  self : ResourceGroup,
  pid~ : @core.ProcessId,
  callback~ : () -> Unit,
) -> Bool {
  // 先检查是否全部可用
  for i in 0..<self.resources.length() {
    if !self.resources[i].is_available() {
      return false
    }
  }
  // 全部可用，逐个获取
  for i in 0..<self.resources.length() {
    let r = self.resources[i]
    ignore(r.request(pid~, callback=fn() { () }))
    self.acquired[i] = true
  }
  callback()
  true
}

///|
/// 批量释放组内所有已获取资源
pub fn ResourceGroup::release_all(self : ResourceGroup) -> Unit {
  for i in 0..<self.resources.length() {
    if self.acquired[i] {
      self.resources[i].release()
      self.acquired[i] = false
    }
  }
}

///|
/// 组内资源数量
pub fn ResourceGroup::size(self : ResourceGroup) -> Int {
  self.resources.length()
}

///|
/// 已获取资源数
pub fn ResourceGroup::acquired_count(self : ResourceGroup) -> Int {
  let mut count = 0
  for a in self.acquired {
    if a {
      count += 1
    }
  }
  count
}
