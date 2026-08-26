///|
/// 示例 3：实验管理与插件接口
///
/// 演示参数遍历、批量运行、快照功能和插件注册。
pub fn run() -> String {
  @simbuf.clear()
  let base = @experiment.new_config(until=50.0, seed=42)
  let configs = @experiment.param_sweep(base~, param_name="load", values=[
    0.5, 1.0, 2.0, 4.0,
  ])
  @simbuf.println("=== 参数遍历实验 ===")
  @simbuf.println("配置数量: \{configs.length()}")
  let results = @experiment.batch_run(configs)
  for i, result in results {
    @simbuf.println(
      "配置 \{i}: load=\{configs[i].params["load"]}, 最终时间=\{result.final_time}",
    )
  }
  let env = @core.new_env(until=30.0)
  let counter : Array[Int] = [0]
  ignore(env.schedule(time=10.0, callback=fn() { counter[0] = counter[0] + 1 }))
  ignore(env.schedule(time=20.0, callback=fn() { counter[0] = counter[0] + 1 }))
  env.run()
  let snap = @experiment.snapshot(env)
  @simbuf.println("=== 单次实验快照 ===")
  @simbuf.println("快照时间: \{snap.time}")
  @simbuf.println("计数器值: \{counter[0]}")
  let mgr = @plugin.new_manager()
  let log_plugin : @plugin.PluginCallbacks = {
    on_step: fn(_env, time) {
      if time == 0.0 {
        @simbuf.println("插件: 仿真开始")
      }
    },
    on_event: fn(_env, _event) { () },
    on_finish: fn(_env) { @simbuf.println("插件: 仿真结束") },
  }
  mgr.register(log_plugin)
  @simbuf.println("已注册插件数: \{mgr.length()}")
  @simbuf.to_string()
}