///|
/// 进程组
///
/// 管理一组进程的集合，跟踪完成状态。
/// `add(process)` 注册进程并自动通过 `on_complete` 跟踪其完成。
/// `on_all_complete(callback)` 注册全部完成时的回调。
///
/// 适用于批量进程管理：工厂并行作业、工作池、并行仿真等。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=50.0)
///   let group = @process.new_process_group(name="workers")
///   let p1 = @process.process(env, name="w1", behavior=fn(_p) {
///     @process.Timeout(duration=10.0, next=fn() { @process.Done })
///   })
///   group.add(p1)
///   assert_eq(group.size(), 1)
///   env.run()
///   assert_true(group.is_all_complete())
/// }
/// ```
pub(all) struct ProcessGroup {
  name : String
  mut members : Array[Process]
  mut completed_count : Int
  all_complete_callbacks : Array[() -> Unit]
}

///|
/// 创建进程组
pub fn new_process_group(name? : String = "") -> ProcessGroup {
  { name, members: [], completed_count: 0, all_complete_callbacks: [] }
}

///|
/// 添加进程到组
///
/// 自动注册 `on_complete` 回调跟踪完成状态。
/// 若进程已完成，立即计入完成数。
pub fn ProcessGroup::add(self : ProcessGroup, process : Process) -> Unit {
  let group_ref = self
  process.on_complete(fn() {
    group_ref.completed_count = group_ref.completed_count + 1
    if group_ref.completed_count == group_ref.members.length() {
      for cb in group_ref.all_complete_callbacks {
        cb()
      }
    }
  })
  self.members.push(process)
}

///|
/// 组大小
pub fn ProcessGroup::size(self : ProcessGroup) -> Int {
  self.members.length()
}

///|
/// 已完成进程数
pub fn ProcessGroup::completed_count(self : ProcessGroup) -> Int {
  self.completed_count
}

///|
/// 未完成进程数
pub fn ProcessGroup::pending_count(self : ProcessGroup) -> Int {
  self.members.length() - self.completed_count
}

///|
/// 是否全部完成
pub fn ProcessGroup::is_all_complete(self : ProcessGroup) -> Bool {
  self.completed_count == self.members.length() && self.members.length() > 0
}

///|
/// 注册全部完成回调
///
/// 当组内所有进程都完成时调用。若已全部完成，立即调用。
pub fn ProcessGroup::on_all_complete(
  self : ProcessGroup,
  callback : () -> Unit,
) -> Unit {
  if self.is_all_complete() {
    callback()
  } else {
    self.all_complete_callbacks.push(callback)
  }
}

///|
/// 组名
pub fn ProcessGroup::name(self : ProcessGroup) -> String {
  self.name
}

///|
/// 成员列表
pub fn ProcessGroup::members(self : ProcessGroup) -> Array[Process] {
  self.members
}

///|
/// 获取指定索引的成员
pub fn ProcessGroup::get(self : ProcessGroup, index : Int) -> Process {
  self.members[index]
}
