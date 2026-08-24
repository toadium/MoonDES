///|
/// 定时器
///
/// 周期性触发回调，间隔为 `interval` 仿真时间单位。
/// `start()` 启动定时器，每次触发后自动重新调度（自重调度）。
/// `stop()` 停止定时器。
///
/// 可设置 `max_count` 限制触发次数（默认无限）。
///
/// 内部使用 `env.schedule` 实现，每次触发后在 `now + interval` 重新调度。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=50.0)
///   let mut count = 0
///   let timer = @timer.new_timer(env, interval=10.0, callback=fn() {
///     count = count + 1
///   })
///   timer.start()
///   env.run()
///   assert_true(count >= 4) // t=10,20,30,40
/// }
/// ```
pub(all) struct Timer {
  env : @core.SimulationEnv
  interval : Double
  callback : () -> Unit
  mut active : Bool
  mut fire_count : Int
  max_count : Int // -1 = unlimited
}

///|
/// 创建定时器
///
/// - `interval`：触发间隔（仿真时间单位）
/// - `callback`：每次触发时调用的回调
/// - `max_count?`：最大触发次数，默认无限（-1）
pub fn new_timer(
  env : @core.SimulationEnv,
  interval~ : Double,
  callback~ : () -> Unit,
  max_count? : Int = -1,
) -> Timer {
  { env, interval, callback, active: false, fire_count: 0, max_count }
}

///|
/// 启动定时器
///
/// 在 `interval` 时间后首次触发，之后每次触发后自动重新调度。
pub fn Timer::start(self : Timer) -> Unit {
  self.active = true
  self.schedule_next()
}

///|
/// 停止定时器
///
/// 取消后续所有触发。已调度的下一次触发仍会执行（无法撤销已入队事件），
/// 但不会再重新调度。
pub fn Timer::stop(self : Timer) -> Unit {
  self.active = false
}

///|
/// 是否活跃
pub fn Timer::is_active(self : Timer) -> Bool {
  self.active
}

///|
/// 已触发次数
pub fn Timer::fire_count(self : Timer) -> Int {
  self.fire_count
}

///|
/// 触发间隔
pub fn Timer::interval(self : Timer) -> Double {
  self.interval
}

///|
/// 内部：调度下一次触发
fn Timer::schedule_next(self : Timer) -> Unit {
  if !self.active {
    return
  }
  if self.max_count >= 0 && self.fire_count >= self.max_count {
    self.active = false
    return
  }
  let next_time = self.env.now() + self.interval
  let self_ref = self
  ignore(self.env.schedule(time=next_time, callback=fn() { self_ref.fire() }))
}

///|
/// 内部：执行触发
fn Timer::fire(self : Timer) -> Unit {
  if !self.active {
    return
  }
  self.fire_count = self.fire_count + 1
  (self.callback)()
  self.schedule_next()
}

///|
/// 重置定时器
///
/// 停止定时器并清零触发计数。
pub fn Timer::reset(self : Timer) -> Unit {
  self.active = false
  self.fire_count = 0
}
