///|
/// 示例：交通系统仿真
///
/// 2 个交叉口，各有红绿灯（FSM: Red→Green→Yellow→Red）。
/// Timer 周期性切换灯色。车辆按指数分布到达（Random），
/// 通过 EventBus 发布到达/离开事件。Stats 统计吞吐量。
///
/// 运行：moon run ./examples/traffic_system --target wasm
fn main {
  let env = @core.new_env(until=200.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 统计
  let mut total_arrivals = 0
  let mut total_pass_through = 0
  let mut intersection1_pass = 0
  let mut intersection2_pass = 0
  let wait_times : Array[Double] = []

  // 监控中心订阅所有事件
  ignore(
    bus.subscribe("arrival", fn(_data) { total_arrivals = total_arrivals + 1 }),
  )
  ignore(
    bus.subscribe("pass_through", fn(data) {
      total_pass_through = total_pass_through + 1
      if data == "I1" {
        intersection1_pass = intersection1_pass + 1
      } else {
        intersection2_pass = intersection2_pass + 1
      }
    }),
  )

  // 创建交叉口 1 的交通灯 FSM
  let light1 = @fsm.new_state_machine(initial="Red", transitions=[
    @fsm.transition(from="Red", to="Green", on="next"),
    @fsm.transition(from="Green", to="Yellow", on="next"),
    @fsm.transition(from="Yellow", to="Red", on="next"),
  ])

  // 创建交叉口 2 的交通灯 FSM
  let light2 = @fsm.new_state_machine(initial="Green", transitions=[
    @fsm.transition(from="Red", to="Green", on="next"),
    @fsm.transition(from="Green", to="Yellow", on="next"),
    @fsm.transition(from="Yellow", to="Red", on="next"),
  ])

  // 定时器：每 15s 切换交通灯
  let light1_ref : Array[@fsm.StateMachine] = []
  let light2_ref : Array[@fsm.StateMachine] = []
  light1_ref.push(light1)
  light2_ref.push(light2)

  let light_timer = @timer.new_timer(env, interval=15.0, callback=fn() {
    ignore(light1_ref[0].fire("next"))
    ignore(light2_ref[0].fire("next"))
  })
  light_timer.start()

  // 车辆到达进程：交叉口 1
  ignore(
    @process.process(env, name="vehicles_1", behavior=fn(_p) {
      let arrive_time = env.now()
      ignore(bus.publish("arrival", "I1"))
      // 等待绿灯
      let wait = @random.exponential(rng, lambda=0.5)
      @process.Timeout(duration=wait, next=fn() {
        wait_times.push(env.now() - arrive_time)
        ignore(bus.publish("pass_through", "I1"))
        let next_arrival = @random.exponential(rng, lambda=0.3)
        @process.Timeout(duration=next_arrival, next=fn() {
          let arrive2 = env.now()
          ignore(bus.publish("arrival", "I1"))
          let wait2 = @random.exponential(rng, lambda=0.5)
          @process.Timeout(duration=wait2, next=fn() {
            wait_times.push(env.now() - arrive2)
            ignore(bus.publish("pass_through", "I1"))
            let next2 = @random.exponential(rng, lambda=0.3)
            @process.Timeout(duration=next2, next=fn() {
              let arrive3 = env.now()
              ignore(bus.publish("arrival", "I1"))
              let wait3 = @random.exponential(rng, lambda=0.5)
              @process.Timeout(duration=wait3, next=fn() {
                wait_times.push(env.now() - arrive3)
                ignore(bus.publish("pass_through", "I1"))
                @process.Done
              })
            })
          })
        })
      })
    }),
  )

  // 车辆到达进程：交叉口 2
  ignore(
    @process.process(env, name="vehicles_2", behavior=fn(_p) {
      let arrive_time = env.now()
      ignore(bus.publish("arrival", "I2"))
      let wait = @random.exponential(rng, lambda=0.4)
      @process.Timeout(duration=wait, next=fn() {
        wait_times.push(env.now() - arrive_time)
        ignore(bus.publish("pass_through", "I2"))
        let next_arrival = @random.exponential(rng, lambda=0.25)
        @process.Timeout(duration=next_arrival, next=fn() {
          let arrive2 = env.now()
          ignore(bus.publish("arrival", "I2"))
          let wait2 = @random.exponential(rng, lambda=0.4)
          @process.Timeout(duration=wait2, next=fn() {
            wait_times.push(env.now() - arrive2)
            ignore(bus.publish("pass_through", "I2"))
            let next2 = @random.exponential(rng, lambda=0.25)
            @process.Timeout(duration=next2, next=fn() {
              let arrive3 = env.now()
              ignore(bus.publish("arrival", "I2"))
              let wait3 = @random.exponential(rng, lambda=0.4)
              @process.Timeout(duration=wait3, next=fn() {
                wait_times.push(env.now() - arrive3)
                ignore(bus.publish("pass_through", "I2"))
                @process.Done
              })
            })
          })
        })
      })
    }),
  )

  env.run()

  println("Traffic System Simulation")
  println("==========================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Traffic Light 1:")
  println("  Current state: \{light1.current()}")
  println("  Transitions:   \{light1.transition_count()}")
  println("  History length: {light1.history().length()}")
  println("Traffic Light 2:")
  println("  Current state: \{light2.current()}")
  println("  Transitions:   \{light2.transition_count()}")
  println("")
  println("Vehicle Statistics:")
  println("  Total arrivals:       \{total_arrivals}")
  println("  Total pass-through:   \{total_pass_through}")
  println("  Intersection 1:       \{intersection1_pass}")
  println("  Intersection 2:       \{intersection2_pass}")
  println("")
  if wait_times.length() > 0 {
    let ws = @stats.summary(wait_times)
    println("Wait Time Statistics:")
    println("  Mean:   \{ws.mean}")
    println("  StdDev: \{ws.stddev}")
    println("  Min:    \{ws.min}")
    println("  Max:    \{ws.max}")
  }
  println("")
  println("Event Bus:")
  println("  Topics: \{bus.topics().length()}")
  println("  Total subscribers: \{bus.total_subscribers()}")
  println("Timer:")
  println("  Fire count: \{light_timer.fire_count()}")
}
