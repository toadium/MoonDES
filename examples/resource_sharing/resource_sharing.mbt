///|
/// 示例 3：实验管理与插件接口
///
/// 演示参数遍历、批量运行、快照功能和插件注册。
fn main {
  let base = @experiment.new_config(until=50.0, seed=42)
  let configs = @experiment.param_sweep(base~, param_name="load", values=[
    0.5, 1.0, 2.0, 4.0,
  ])
  println("=== 参数遍历实验 ===")
  println("配置数量: \{configs.length()}")
  let results = @experiment.batch_run(configs)
  for i, result in results {
    println(
      "配置 \{i}: load=\{configs[i].params["load"]}, 最终时间=\{result.final_time}",
    )
  }
  let env = @core.new_env(until=30.0)
  let counter : Array[Int] = [0]
  ignore(env.schedule(time=10.0, callback=fn() { counter[0] = counter[0] + 1 }))
  ignore(env.schedule(time=20.0, callback=fn() { counter[0] = counter[0] + 1 }))
  env.run()
  let snap = @experiment.snapshot(env)
  println("=== 单次实验快照 ===")
  println("快照时间: \{snap.time}")
  println("计数器值: \{counter[0]}")
  let mgr = @plugin.new_manager()
  let log_plugin : @plugin.PluginCallbacks = {
    on_step: fn(_env, time) {
      if time == 0.0 {
        println("插件: 仿真开始")
      }
    },
    on_event: fn(_env, _event) { () },
    on_finish: fn(_env) { println("插件: 仿真结束") },
  }
  mgr.register(log_plugin)
  println("已注册插件数: \{mgr.length()}")
}
