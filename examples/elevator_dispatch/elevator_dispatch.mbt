///|
/// 示例：电梯调度仿真
///
/// 2 部电梯服务 10 层楼。每部电梯有状态机：
///   Idle → Moving → DoorOpen → Idle
///
/// 乘客请求通过 EventBus 发布，电梯接收请求后移动到目标楼层。
/// ProcessGroup 管理所有电梯进程，等待全部完成。
/// Timer 控制门开关时间，Stats 统计等待时间。
///
/// 运行：moon run ./examples/elevator_dispatch --target wasm
pub fn run() -> String {
  @simbuf.clear()
  let env = @core.new_env(until=300.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 统计
  let mut requests_served = 0
  let mut elevator1_trips = 0
  let mut elevator2_trips = 0
  let wait_times : Array[Double] = []

  // 监控：统计服务数
  ignore(
    bus.subscribe("served", fn(data) {
      requests_served = requests_served + 1
      if data == "E1" {
        elevator1_trips = elevator1_trips + 1
      } else {
        elevator2_trips = elevator2_trips + 1
      }
    }),
  )

  // 电梯 1 状态机
  let fsm1 = @fsm.new_state_machine(initial="Idle", transitions=[
    @fsm.transition(from="Idle", to="Moving", on="dispatch"),
    @fsm.transition(from="Moving", to="DoorOpen", on="arrived"),
    @fsm.transition(from="DoorOpen", to="Idle", on="close"),
  ])

  // 电梯 2 状态机
  let fsm2 = @fsm.new_state_machine(initial="Idle", transitions=[
    @fsm.transition(from="Idle", to="Moving", on="dispatch"),
    @fsm.transition(from="Moving", to="DoorOpen", on="arrived"),
    @fsm.transition(from="DoorOpen", to="Idle", on="close"),
  ])

  let fsm1_ref : Array[@fsm.StateMachine] = []
  let fsm2_ref : Array[@fsm.StateMachine] = []
  fsm1_ref.push(fsm1)
  fsm2_ref.push(fsm2)

  // 创建进程组管理电梯
  let group = @process.new_process_group(name="elevators")

  // 电梯 1 进程
  let e1 = @process.process(env, name="Elevator1", behavior=fn(_p) {
    // 接收请求并服务
    let request_time = env.now()
    let travel_time = 5.0 + @random.exponential(rng, lambda=0.2)
    ignore(fsm1_ref[0].fire("dispatch"))
    @process.Timeout(duration=travel_time, next=fn() {
      ignore(fsm1_ref[0].fire("arrived"))
      // 开门等待
      let door_time = 3.0
      @process.Timeout(duration=door_time, next=fn() {
        ignore(fsm1_ref[0].fire("close"))
        wait_times.push(env.now() - request_time)
        ignore(bus.publish("served", "E1"))
        // 下一轮
        let idle_time = @random.exponential(rng, lambda=0.5)
        @process.Timeout(duration=idle_time, next=fn() {
          let rt2 = env.now()
          let tt2 = 5.0 + @random.exponential(rng, lambda=0.2)
          ignore(fsm1_ref[0].fire("dispatch"))
          @process.Timeout(duration=tt2, next=fn() {
            ignore(fsm1_ref[0].fire("arrived"))
            @process.Timeout(duration=3.0, next=fn() {
              ignore(fsm1_ref[0].fire("close"))
              wait_times.push(env.now() - rt2)
              ignore(bus.publish("served", "E1"))
              @process.Done
            })
          })
        })
      })
    })
  })
  group.add(e1)

  // 电梯 2 进程
  let e2 = @process.process(env, name="Elevator2", behavior=fn(_p) {
    let request_time = env.now()
    let travel_time = 4.0 + @random.exponential(rng, lambda=0.3)
    ignore(fsm2_ref[0].fire("dispatch"))
    @process.Timeout(duration=travel_time, next=fn() {
      ignore(fsm2_ref[0].fire("arrived"))
      let door_time = 3.0
      @process.Timeout(duration=door_time, next=fn() {
        ignore(fsm2_ref[0].fire("close"))
        wait_times.push(env.now() - request_time)
        ignore(bus.publish("served", "E2"))
        let idle_time = @random.exponential(rng, lambda=0.4)
        @process.Timeout(duration=idle_time, next=fn() {
          let rt2 = env.now()
          let tt2 = 4.0 + @random.exponential(rng, lambda=0.3)
          ignore(fsm2_ref[0].fire("dispatch"))
          @process.Timeout(duration=tt2, next=fn() {
            ignore(fsm2_ref[0].fire("arrived"))
            @process.Timeout(duration=3.0, next=fn() {
              ignore(fsm2_ref[0].fire("close"))
              wait_times.push(env.now() - rt2)
              ignore(bus.publish("served", "E2"))
              @process.Done
            })
          })
        })
      })
    })
  })
  group.add(e2)

  // 乘客请求进程：定期发布请求
  let mut total_requests = 0
  ignore(
    @process.process(env, name="passengers", behavior=fn(_p) {
      total_requests = total_requests + 1
      ignore(
        bus.publish("request", "floor=\{@random.randint(rng, min=1, max=10)}"),
      )
      let next_request = @random.exponential(rng, lambda=0.2)
      @process.Timeout(duration=next_request, next=fn() {
        total_requests = total_requests + 1
        ignore(
          bus.publish("request", "floor=\{@random.randint(rng, min=1, max=10)}"),
        )
        let nr2 = @random.exponential(rng, lambda=0.2)
        @process.Timeout(duration=nr2, next=fn() {
          total_requests = total_requests + 1
          ignore(
            bus.publish(
              "request",
              "floor=\{@random.randint(rng, min=1, max=10)}",
            ),
          )
          @process.Done
        })
      })
    }),
  )

  // 全部电梯完成时的回调
  let mut all_elevators_done = false
  group.on_all_complete(fn() { all_elevators_done = true })

  env.run()

  @simbuf.println("Elevator Dispatch Simulation")
  @simbuf.println("============================")
  @simbuf.println("Simulation time: \{env.now()}")
  @simbuf.println("Events processed: \{env.event_count()}")
  @simbuf.println("")
  @simbuf.println("Process Group:")
  @simbuf.println("  Name: \{group.name()}")
  @simbuf.println("  Size: \{group.size()}")
  @simbuf.println("  Completed: \{group.completed_count()}")
  @simbuf.println("  All done: \{all_elevators_done}")
  @simbuf.println("")
  @simbuf.println("Elevator 1 (FSM):")
  @simbuf.println("  Current state: \{fsm1.current()}")
  @simbuf.println("  Transitions: \{fsm1.transition_count()}")
  @simbuf.println("  History: \{fsm1.history().length()} states")
  @simbuf.println("Elevator 2 (FSM):")
  @simbuf.println("  Current state: \{fsm2.current()}")
  @simbuf.println("  Transitions: \{fsm2.transition_count()}")
  @simbuf.println("  History: \{fsm2.history().length()} states")
  @simbuf.println("")
  @simbuf.println("Statistics:")
  @simbuf.println("  Total requests: \{total_requests}")
  @simbuf.println("  Requests served: \{requests_served}")
  @simbuf.println("  Elevator 1 trips: \{elevator1_trips}")
  @simbuf.println("  Elevator 2 trips: \{elevator2_trips}")
  @simbuf.println("")
  if wait_times.length() > 0 {
    let ws = @stats.summary(wait_times)
    @simbuf.println("Wait Time Statistics:")
    @simbuf.println("  Count:  \{wait_times.length()}")
    @simbuf.println("  Mean:   \{ws.mean}")
    @simbuf.println("  StdDev: \{ws.stddev}")
    @simbuf.println("  Min:    \{ws.min}")
    @simbuf.println("  Max:    \{ws.max}")
  }
  @simbuf.to_string()
}