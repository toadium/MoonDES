# plugin — 插件接口层

> MoonDES 层级5：标准化仿真组件挂载接口，引擎自动调用生命周期回调。

## API 概览

| 符号 | 说明 |
|------|------|
| `PluginCallbacks` | 插件回调集合（on_step / on_event / on_finish） |
| `PluginManager` | 插件管理器 |
| `new_manager()` | 创建空插件管理器 |
| `null_callbacks()` | 创建空操作回调 |
| `PluginManager::register(plugin)` | 注册插件 |
| `attach(env, manager)` | 挂载到仿真环境 |

## 示例

```mbt check
///|
test {
  let mgr = new_manager()
  inspect(mgr.length(), content="0")
  let cb = null_callbacks()
  mgr.register(cb)
  inspect(mgr.length(), content="1")
}
```

```mbt check
///|
test {
  let env = @core.new_env(until=10.0)
  let mgr = new_manager()
  let step_count : Array[Int] = [0]
  let cb : PluginCallbacks = {
    on_step: fn(_env, _time) { step_count[0] = step_count[0] + 1 },
    on_event: fn(_env, _event) { () },
    on_finish: fn(_env) { () },
  }
  mgr.register(cb)
  attach(env, mgr)
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  env.run()
  inspect(step_count[0], content="1")
}
```