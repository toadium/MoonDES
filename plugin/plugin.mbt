///|
/// 仿真插件回调集合
///
/// 外部业务模型可创建 PluginCallbacks 注册至引擎内部，
/// 在指定仿真时间步被引擎自动调用执行计算。
pub(all) struct PluginCallbacks {
  on_step : (@core.SimulationEnv, Double) -> Unit
  on_event : (@core.SimulationEnv, @core.Event) -> Unit
  on_finish : (@core.SimulationEnv) -> Unit
}

///|
/// 创建空操作插件回调
pub fn null_callbacks() -> PluginCallbacks {
  {
    on_step: fn(_env, _time) { () },
    on_event: fn(_env, _event) { () },
    on_finish: fn(_env) { () },
  }
}

///|
/// 插件管理器
pub(all) struct PluginManager {
  plugins : Array[PluginCallbacks]
}

///|
/// 创建空插件管理器
pub fn new_manager() -> PluginManager {
  { plugins: [] }
}

///|
/// 注册插件
pub fn PluginManager::register(
  self : PluginManager,
  plugin : PluginCallbacks,
) -> Unit {
  self.plugins.push(plugin)
}

///|
/// 已注册插件数量
pub fn PluginManager::length(self : PluginManager) -> Int {
  self.plugins.length()
}

///|
/// 通知所有插件仿真步开始
pub fn PluginManager::notify_step(
  self : PluginManager,
  env : @core.SimulationEnv,
  current_time : Double,
) -> Unit {
  for p in self.plugins {
    (p.on_step)(env, current_time)
  }
}

///|
/// 通知所有插件事件触发
pub fn PluginManager::notify_event(
  self : PluginManager,
  env : @core.SimulationEnv,
  event : @core.Event,
) -> Unit {
  for p in self.plugins {
    (p.on_event)(env, event)
  }
}

///|
/// 通知所有插件仿真结束
pub fn PluginManager::notify_finish(
  self : PluginManager,
  env : @core.SimulationEnv,
) -> Unit {
  for p in self.plugins {
    (p.on_finish)(env)
  }
}

///|
/// 将插件管理器挂载到仿真环境
///
/// 挂载后，引擎在 `run` / `step` 中自动调用：
/// - `on_step`：每个事件处理前
/// - `on_event`：事件触发后
/// - `on_finish`：仿真结束时（仅一次）
pub fn attach(env : @core.SimulationEnv, manager : PluginManager) -> Unit {
  env._set_on_step_hook(Some(fn(e, t) { manager.notify_step(e, t) }))
  env._set_on_event_hook(Some(fn(e, ev) { manager.notify_event(e, ev) }))
  env._set_on_finish_hook(Some(fn(e) { manager.notify_finish(e) }))
}
