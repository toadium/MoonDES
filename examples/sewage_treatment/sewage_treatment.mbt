///|
/// 示例：污水处理厂仿真
///
/// 工艺流程：进水 → 格栅 → 初沉 → 曝气 → 二沉 → 消毒 → 排放
/// 污水按指数分布流入，每个阶段用 Pipeline 描述，Resource 限制容量。
/// FSM 跟踪出水达标状态，EventBus 发布超标告警，Stats 统计处理时间。
///
/// 运行：moon run ./examples/sewage_treatment --target wasm
fn main {
  let env = @core.new_env(until=300.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 定义工艺流水线
  let plant = @pipeline.new_pipeline()
  plant.add_stage(name="进水", capacity=25, processing_time=1.0)
  plant.add_stage(name="格栅", capacity=20, processing_time=2.0)
  plant.add_stage(name="初沉", capacity=15, processing_time=10.0)
  plant.add_stage(name="曝气", capacity=12, processing_time=20.0)
  plant.add_stage(name="二沉", capacity=10, processing_time=12.0)
  plant.add_stage(name="消毒", capacity=15, processing_time=4.0)
  plant.add_stage(name="排放", capacity=30, processing_time=1.0)

  // 为每个阶段创建资源
  let stage_resources : Array[@resource.Resource] = []
  for i in 0..<plant.stage_count() {
    let s = plant.get(i)
    stage_resources.push(
      @resource.new_capacity(name=s.name, capacity=s.capacity),
    )
  }

  // 出水达标状态机：Compliant → Marginal → NonCompliant → Adjusting → Compliant
  let quality_fsm = @fsm.new_state_machine(initial="Compliant", transitions=[
    @fsm.transition(from="Compliant", to="Marginal", on="marginal"),
    @fsm.transition(from="Marginal", to="NonCompliant", on="exceed"),
    @fsm.transition(from="NonCompliant", to="Adjusting", on="adjust"),
    @fsm.transition(from="Adjusting", to="Compliant", on="restored"),
    @fsm.transition(from="Marginal", to="Compliant", on="recovered"),
  ])

  // 统计
  let mut total_inflow = 0
  let mut total_discharged = 0
  let mut exceedance_events = 0
  let treatment_times : Array[Double] = []
  let mut avg_inflow_rate = 0.0

  // 监控
  ignore(
    bus.subscribe("exceedance", fn(_data) {
      exceedance_events = exceedance_events + 1
    }),
  )
  ignore(
    bus.subscribe("discharged", fn(_data) {
      total_discharged = total_discharged + 1
    }),
  )

  let fsm_ref : Array[@fsm.StateMachine] = []
  fsm_ref.push(quality_fsm)

  // 污水处理进程
  ignore(
    @process.process(env, name="sewage_flow", behavior=fn(p) {
      // 批次 1
      total_inflow = total_inflow + 1
      let batch_start = env.now()
      // 水质检测
      let cod = 50.0 + @random.normal(rng, mean=0.0, std=15.0)
      if cod > 80.0 {
        ignore(fsm_ref[0].fire("exceed"))
        ignore(bus.publish("exceedance", "COD=\{cod}"))
      } else if cod > 60.0 {
        ignore(fsm_ref[0].fire("marginal"))
      }
      // 依次通过 7 个阶段
      let process_stage = fn(
        stage_idx : Int,
        next : () -> @process.ProcessAction,
      ) {
        let stage = plant.get(stage_idx)
        ignore(
          stage_resources[stage_idx].request(pid=p.id(), callback=fn() {
            let pt = stage.processing_time +
              @random.normal(rng, mean=0.0, std=2.0)
            let actual_pt = if pt > 0.0 { pt } else { stage.processing_time }
            ignore(
              env.schedule(time=env.now() + actual_pt, callback=fn() {
                stage_resources[stage_idx].release()
              }),
            )
          }),
        )
        @process.Timeout(duration=stage.processing_time + 2.0, next~)
      }
      process_stage(0, fn() {
        process_stage(1, fn() {
          process_stage(2, fn() {
            process_stage(3, fn() {
              process_stage(4, fn() {
                process_stage(5, fn() {
                  process_stage(6, fn() {
                    treatment_times.push(env.now() - batch_start)
                    ignore(bus.publish("discharged", "batch1"))
                    // 出水恢复
                    if fsm_ref[0].current() == "NonCompliant" {
                      ignore(fsm_ref[0].fire("adjust"))
                    } else if fsm_ref[0].current() == "Marginal" {
                      ignore(fsm_ref[0].fire("recovered"))
                    }
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

  // 第二个处理进程
  ignore(
    @process.process(env, name="sewage_flow_2", behavior=fn(p) {
      @process.Timeout(duration=25.0, next=fn() {
        total_inflow = total_inflow + 1
        let batch_start = env.now()
        let process_stage = fn(
          stage_idx : Int,
          next : () -> @process.ProcessAction,
        ) {
          let stage = plant.get(stage_idx)
          ignore(
            stage_resources[stage_idx].request(pid=p.id(), callback=fn() {
              let pt = stage.processing_time +
                @random.normal(rng, mean=0.0, std=2.0)
              let actual_pt = if pt > 0.0 { pt } else { stage.processing_time }
              ignore(
                env.schedule(time=env.now() + actual_pt, callback=fn() {
                  stage_resources[stage_idx].release()
                }),
              )
            }),
          )
          @process.Timeout(duration=stage.processing_time + 2.0, next~)
        }
        process_stage(0, fn() {
          process_stage(1, fn() {
            process_stage(2, fn() {
              process_stage(3, fn() {
                process_stage(4, fn() {
                  process_stage(5, fn() {
                    process_stage(6, fn() {
                      treatment_times.push(env.now() - batch_start)
                      ignore(bus.publish("discharged", "batch2"))
                      @process.Done
                    })
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

  if env.now() > 0.0 {
    avg_inflow_rate = total_inflow.to_double() / env.now() * 60.0
  }

  println("Sewage Treatment Plant Simulation")
  println("==================================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Treatment Pipeline:")
  println(plant.to_string())
  println("")
  println("Bottleneck stage:")
  match plant.bottleneck() {
    Some(idx) =>
      println("  \{plant.get(idx).name} (capacity=\{plant.get(idx).capacity})")
    None => println("  N/A")
  }
  println("")
  println("Quality FSM:")
  println("  Current state: \{quality_fsm.current()}")
  println("  Transitions:   \{quality_fsm.transition_count()}")
  println("  History:       \{quality_fsm.history().length()} states")
  println("")
  println("Treatment Statistics:")
  println("  Total inflow batches:  \{total_inflow}")
  println("  Total discharged:      \{total_discharged}")
  println("  Exceedance events:     \{exceedance_events}")
  println("  Avg inflow rate:       \{avg_inflow_rate} batches/hour")
  println("")
  if treatment_times.length() > 0 {
    let ts = @stats.summary(treatment_times)
    println("Treatment Time Statistics:")
    println("  Count:  \{treatment_times.length()}")
    println("  Mean:   \{ts.mean}")
    println("  StdDev: \{ts.stddev}")
    println("  Min:    \{ts.min}")
    println("  Max:    \{ts.max}")
  }
  println("")
  println("Event Bus:")
  println("  Topics: \{bus.topics().length()}")
  println("  Subscribers: \{bus.total_subscribers()}")
}
