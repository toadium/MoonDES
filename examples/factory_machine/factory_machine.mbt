///|
/// 示例：工厂设备状态机仿真
///
/// 一台工厂设备在以下状态间循环：
///   Idle → Working → Idle（正常完成）
///   Working → Broken → Repairing → Idle（故障维修）
///
/// 使用 FSM 管理状态，Process 驱动时间推进，
/// Random 模拟故障概率和服务时间。
///
/// 运行：moon run ./examples/factory_machine --target wasm
fn main {
  let env = @core.new_env(until=500.0)
  let rng = @random.new_rng()

  // 创建状态机
  let sm = @fsm.new_state_machine(initial="Idle", transitions=[
    @fsm.transition(from="Idle", to="Working", on="start"),
    @fsm.transition(from="Working", to="Idle", on="complete"),
    @fsm.transition(from="Working", to="Broken", on="breakdown"),
    @fsm.transition(from="Broken", to="Repairing", on="repair"),
    @fsm.transition(from="Repairing", to="Idle", on="fixed"),
  ])

  // 统计
  let mut jobs_completed = 0
  let mut breakdowns = 0
  let mut total_work_time = 0.0
  let mut total_repair_time = 0.0
  let state_log : Array[String] = []

  // 注册状态回调
  sm.on_enter("Working", fn(_s) {
    state_log.push("[t=\{env.now()}] → Working")
  })
  sm.on_enter("Broken", fn(_s) {
    breakdowns = breakdowns + 1
    state_log.push("[t=\{env.now()}] → Broken!")
  })
  sm.on_enter("Repairing", fn(_s) {
    state_log.push("[t=\{env.now()}] → Repairing")
  })
  sm.on_enter("Idle", fn(_s) { state_log.push("[t=\{env.now()}] → Idle") })

  // 设备进程：循环工作
  ignore(
    @process.process(env, name="machine", behavior=fn(_p) {
      // 开始工作
      ignore(sm.fire("start"))
      let work_start = env.now()
      let work_duration = @random.exponential(rng, lambda=0.1)
      // 模拟工作过程：以 5% 概率故障
      let r = @random.uniform(rng, min=0.0, max=1.0)
      if r < 0.05 {
        // 故障
        @process.Timeout(duration=work_duration / 2.0, next=fn() {
          total_work_time = total_work_time + (env.now() - work_start)
          ignore(sm.fire("breakdown"))
          // 维修
          let repair_start = env.now()
          @process.Timeout(duration=2.0, next=fn() {
            ignore(sm.fire("repair"))
            let repair_duration = @random.exponential(rng, lambda=0.5)
            @process.Timeout(duration=repair_duration, next=fn() {
              total_repair_time = total_repair_time + (env.now() - repair_start)
              ignore(sm.fire("fixed"))
              // 下一轮
              let idle_duration = @random.exponential(rng, lambda=1.0)
              @process.Timeout(duration=idle_duration, next=fn() {
                @process.Done
              })
            })
          })
        })
      } else {
        @process.Timeout(
          // 正常完成
          duration=work_duration,
          next=fn() {
            total_work_time = total_work_time + (env.now() - work_start)
            jobs_completed = jobs_completed + 1
            ignore(sm.fire("complete"))
            // 闲置后重新开始
            let idle_duration = @random.exponential(rng, lambda=1.0)
            @process.Timeout(duration=idle_duration, next=fn() { @process.Done })
          },
        )
      }
    }),
  )

  env.run()

  println("Factory Machine FSM Simulation")
  println("==============================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Results:")
  println("  Jobs completed:    \{jobs_completed}")
  println("  Breakdowns:        \{breakdowns}")
  println("  Total work time:   \{total_work_time}")
  println("  Total repair time: \{total_repair_time}")
  println("  State transitions: \{sm.transition_count()}")
  println("  Final state:       \{sm.current()}")
  println("")
  println("State history (last 20):")
  let h = sm.history()
  let start = if h.length() > 20 { h.length() - 20 } else { 0 }
  for i in start..<h.length() {
    println("  \{i}: \{h[i]}")
  }
}
