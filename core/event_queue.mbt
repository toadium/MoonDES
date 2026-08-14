///|
/// 最小堆优先级事件队列
///
/// 按 `(time, priority)` 维护最小堆，保证每次弹出的是时间最早、优先级最高的事件。
/// 这是离散事件仿真时序正确性的核心保证。
pub(all) struct EventQueue {
  mut heap : Array[Event]
}

///|
/// 创建空事件队列
pub fn new_queue() -> EventQueue {
  { heap: [] }
}

///|
/// 队列是否为空
pub fn EventQueue::is_empty(self : EventQueue) -> Bool {
  self.heap.length() == 0
}

///|
/// 队列中事件数量
pub fn EventQueue::length(self : EventQueue) -> Int {
  self.heap.length()
}

///|
/// 插入事件到队列（上浮调整）
pub fn EventQueue::push(self : EventQueue, event : Event) -> Unit {
  self.heap.push(event)
  self._sift_up(self.heap.length() - 1)
}

///|
/// 查看堆顶事件（不弹出），返回 None 如果队列为空
pub fn EventQueue::peek(self : EventQueue) -> Event? {
  if self.heap.length() == 0 {
    None
  } else {
    Some(self.heap[0])
  }
}

///|
/// 弹出堆顶事件（下沉调整），返回 None 如果队列为空
pub fn EventQueue::pop(self : EventQueue) -> Event? {
  let n = self.heap.length()
  if n == 0 {
    return None
  }
  let top = self.heap[0]
  let last = self.heap.remove(n - 1)
  if self.heap.length() > 0 {
    self.heap[0] = last
    self._sift_down(0)
  }
  Some(top)
}

///|
/// 移除所有已取消的事件（惰性清理）
pub fn EventQueue::remove_canceled(self : EventQueue) -> Unit {
  let active : Array[Event] = []
  for e in self.heap {
    if e.is_pending() {
      active.push(e)
    }
  }
  self.heap = active
  // 元素少于 2 个时已是堆，无需调整
  if self.heap.length() < 2 {
    return
  }
  // 重新建堆：从最后一个非叶节点顺序下沉到根
  let start = self.heap.length() / 2 - 1
  for i in 0..<=start {
    self._sift_down(start - i)
  }
}

///|
/// 上浮操作：将位置 i 的元素向上调整直到满足堆性质
fn EventQueue::_sift_up(self : EventQueue, i_param : Int) -> Unit {
  let mut i = i_param
  while i > 0 {
    let parent = (i - 1) / 2
    if event_compare(self.heap[i], self.heap[parent]) < 0 {
      let tmp = self.heap[i]
      self.heap[i] = self.heap[parent]
      self.heap[parent] = tmp
      i = parent
    } else {
      break
    }
  }
}

///|
/// 下沉操作：将位置 i 的元素向下调整直到满足堆性质
fn EventQueue::_sift_down(self : EventQueue, i_param : Int) -> Unit {
  let mut i = i_param
  let n = self.heap.length()
  while true {
    let left = 2 * i + 1
    let right = 2 * i + 2
    let mut smallest = i
    if left < n && event_compare(self.heap[left], self.heap[smallest]) < 0 {
      smallest = left
    }
    if right < n && event_compare(self.heap[right], self.heap[smallest]) < 0 {
      smallest = right
    }
    if smallest == i {
      break
    }
    let tmp = self.heap[i]
    self.heap[i] = self.heap[smallest]
    self.heap[smallest] = tmp
    i = smallest
  }
}
