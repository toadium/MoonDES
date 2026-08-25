///|
/// 示例：自来水厂仿真
///
/// 工艺流程：取水 → 混凝 → 沉淀 → 过滤 → 消毒 → 供水
/// 每个阶段用 Pipeline 描述，Resource 限制容量，Process 驱动水流。
/// FSM 跟踪厂区运行状态，EventBus 发布水质告警，Timer 定期采样。
///
/// 运行：moon run ./examples/water_treatment --target wasm
fn main {
  let env = @core.new_env(until=300.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 定义工艺流水线
  let plant = @pipeline.new_pipeline()
  plant.add_stage(name="取水", capacity=20, processing_time=2.0)
  plant.add_stage(name="混凝", capacity=15, processing_time=5.0)
  plant.add_stage(name="沉淀", capacity=10, processing_time=15.0)
  plant.add_stage(name="过滤", capacity=8, processing_time=8.0)
  plant.add_stage(name="消毒", capacity=12, processing_time=3.0)
  plant.add_stage(name="供水", capacity=30, processing_time=1.0)

  // 为每个阶段创建资源
  let stage_resources : Array[@resource.Resource] = []
  for i in 0..<plant.stage_count() {
    let s = plant.get(i)
    stage_resources.push(
      @resource.new_capacity(name=s.name, capacity=s.capacity),
    )
  }

  // 厂区状态机：Normal → Warning → Emergency → Maintenance → Normal
  let plant_fsm = @fsm.new_state_machine(initial="Normal", transitions=[
    @fsm.transition(from="Normal", to="Warning", on="quality_drop"),
    @fsm.transition(from="Warning", to="Emergency", on="critical"),
    @fsm.transition(from="Emergency", to="Maintenance", on="shutdown"),
    @fsm.transition(from="Maintenance", to="Normal", on="restart"),
    @fsm.transition(from="Warning", to="Normal", on="recovered"),
  ])

  // 统计
  let mut total_batches = 0
  let mut batches_completed = 0
  let mut quality_alerts = 0
  let processing_times : Array[Double] = []
  let mut current_throughput = 0.0

  // 监控
  ignore(
    bus.subscribe("quality_alert", fn(_data) {
      quality_alerts = quality_alerts + 1
    }),
  )
  ignore(
    bus.subscribe("batch_done", fn(_data) {
      batches_completed = batches_completed + 1
    }),
  )

  // 定期水质采样定时器
  let fsm_ref : Array[@fsm.StateMachine] = []
  fsm_ref.push(plant_fsm)
  let sample_timer = @timer.new_timer(
    env,
    interval=30.0,
    callback=fn() {
      let quality = @random.uniform(rng, min=0.0, max=1.0)
      if quality < 0.05 {
        ignore(fsm_ref[0].fire("critical"))
        ignore(bus.publish("quality_alert", "critical"))
      } else if quality < 0.15 {
        ignore(fsm_ref[0].fire("quality_drop"))
        ignore(bus.publish("quality_alert", "warning"))
      } else if fsm_ref[0].current() == "Warning" {
        ignore(fsm_ref[0].fire("recovered"))
      }
    },
    max_count=8,
  )
  sample_timer.start()

  // 水处理进程
  ignore(
    @process.process(env, name="water_flow", behavior=fn(p) {
      // 批次 1
      total_batches = total_batches + 1
      let batch_start = env.now()
      // 通过每个阶段
      let process_stage = fn(
        stage_idx : Int,
        next : () -> @process.ProcessAction,
      ) {
        let stage = plant.get(stage_idx)
        ignore(
          stage_resources[stage_idx].request(pid=p.id(), callback=fn() {
            let pt = stage.processing_time +
              @random.normal(rng, mean=0.0, std=1.0)
            let actual_pt = if pt > 0.0 { pt } else { stage.processing_time }
            ignore(
              env.schedule(time=env.now() + actual_pt, callback=fn() {
                stage_resources[stage_idx].release()
              }),
            )
          }),
        )
        @process.Timeout(duration=stage.processing_time + 1.0, next~)
      }
      // 依次通过 6 个阶段
      process_stage(0, fn() {
        process_stage(1, fn() {
          process_stage(2, fn() {
            process_stage(3, fn() {
              process_stage(4, fn() {
                process_stage(5, fn() {
                  processing_times.push(env.now() - batch_start)
                  ignore(bus.publish("batch_done", "batch1"))
                  @process.Done
                })
              })
            })
          })
        })
      })
    }),
  )

  // 第二个水处理进程（错开启动）
  ignore(
    @process.process(env, name="water_flow_2", behavior=fn(p) {
      @process.Timeout(duration=20.0, next=fn() {
        total_batches = total_batches + 1
        let batch_start = env.now()
        let process_stage = fn(
          stage_idx : Int,
          next : () -> @process.ProcessAction,
        ) {
          let stage = plant.get(stage_idx)
          ignore(
            stage_resources[stage_idx].request(pid=p.id(), callback=fn() {
              let pt = stage.processing_time +
                @random.normal(rng, mean=0.0, std=1.0)
              let actual_pt = if pt > 0.0 { pt } else { stage.processing_time }
              ignore(
                env.schedule(time=env.now() + actual_pt, callback=fn() {
                  stage_resources[stage_idx].release()
                }),
              )
            }),
          )
          @process.Timeout(duration=stage.processing_time + 1.0, next~)
        }
        process_stage(0, fn() {
          process_stage(1, fn() {
            process_stage(2, fn() {
              process_stage(3, fn() {
                process_stage(4, fn() {
                  process_stage(5, fn() {
                    processing_times.push(env.now() - batch_start)
                    ignore(bus.publish("batch_done", "batch2"))
                    @process.Done
                  })
                })
              })
            })
          })
        })
      })
    }),
  )

  env.run()

  // 计算吞吐量
  if env.now() > 0.0 {
    current_throughput = batches_completed.to_double() / env.now() * 60.0 // 批次/小时
  }

  println("Water Treatment Plant Simulation")
  println("=================================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Plant Pipeline:")
  println(plant.to_string())
  println("")
  println("")
  println("Bottleneck stage:")
  match plant.bottleneck() {
    Some(idx) =>
      println("  \{plant.get(idx).name} (capacity=\{plant.get(idx).capacity})")
    None => println("  N/A")
  }
  println("")
  println("Plant FSM:")
  println("  Current state: \{plant_fsm.current()}")
  println("  Transitions:   \{plant_fsm.transition_count()}")
  println("  History:       \{plant_fsm.history().length()} states")
  println("")
  println("Production Statistics:")
  println("  Total batches:       \{total_batches}")
  println("  Batches completed:   \{batches_completed}")
  println("  Quality alerts:      \{quality_alerts}")
  println("  Throughput:          \{current_throughput} batches/hour")
  println("")
  if processing_times.length() > 0 {
    let ps = @stats.summary(processing_times)
    println("Processing Time Statistics:")
    println("  Count:  \{processing_times.length()}")
    println("  Mean:   \{ps.mean}")
    println("  StdDev: \{ps.stddev}")
    println("  Min:    \{ps.min}")
    println("  Max:    \{ps.max}")
  }
  println("")
  println("Event Bus:")
  println("  Topics: \{bus.topics().length()}")
  println("  Subscribers: \{bus.total_subscribers()}")
  println("Timer:")
  println("  Sample fires: \{sample_timer.fire_count()}")
}
