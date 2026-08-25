///|
/// 示例：医院急诊室仿真
///
/// 患者按指数分布到达急诊室，经分诊后分配病床接受治疗。
///
/// 患者状态机：Waiting → Triaged → InTreatment → Discharged
/// 病床为有限资源（Resource，容量 3）
/// 重症患者通过 EventBus 发布告警
/// Stats 统计等待时间和治疗时间
///
/// 运行：moon run ./examples/hospital_er --target wasm
fn main {
  let env = @core.new_env(until=200.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 病床资源：3 张病床
  let beds = @resource.new_capacity(name="beds", capacity=3)

  // 统计
  let mut total_patients = 0
  let mut critical_patients = 0
  let mut treated_patients = 0
  let wait_times : Array[Double] = []
  let treatment_times : Array[Double] = []

  // 监控：告警
  ignore(
    bus.subscribe("critical_alert", fn(_data) {
      critical_patients = critical_patients + 1
    }),
  )
  ignore(
    bus.subscribe("discharged", fn(_data) {
      treated_patients = treated_patients + 1
    }),
  )

  // 患者状态机
  let patient_fsm = @fsm.new_state_machine(initial="Waiting", transitions=[
    @fsm.transition(from="Waiting", to="Triaged", on="triage"),
    @fsm.transition(from="Triaged", to="InTreatment", on="admit"),
    @fsm.transition(from="InTreatment", to="Discharged", on="discharge"),
  ])

  // 到达进程
  ignore(
    @process.process(env, name="arrivals", behavior=fn(p) {
      // 患者 1
      total_patients = total_patients + 1
      let arrive1 = env.now()
      let is_critical1 = @random.uniform(rng, min=0.0, max=1.0) < 0.2
      if is_critical1 {
        ignore(bus.publish("critical_alert", "patient1"))
      }
      let triage1 = if is_critical1 {
        1.0
      } else {
        3.0 + @random.exponential(rng, lambda=0.5)
      }
      @process.Timeout(duration=triage1, next=fn() {
        ignore(patient_fsm.fire("triage"))
        ignore(
          beds.request(pid=p.id(), callback=fn() {
            ignore(patient_fsm.fire("admit"))
            wait_times.push(env.now() - arrive1)
            let treat1 = if is_critical1 {
              20.0 + @random.exponential(rng, lambda=0.1)
            } else {
              10.0 + @random.exponential(rng, lambda=0.2)
            }
            let treat_start1 = env.now()
            ignore(
              env.schedule(time=env.now() + treat1, callback=fn() {
                ignore(patient_fsm.fire("discharge"))
                treatment_times.push(env.now() - treat_start1)
                ignore(bus.publish("discharged", "patient1"))
                beds.release()
              }),
            )
          }),
        )
        // 患者 2
        total_patients = total_patients + 1
        let arrive2 = env.now()
        let is_critical2 = @random.uniform(rng, min=0.0, max=1.0) < 0.2
        if is_critical2 {
          ignore(bus.publish("critical_alert", "patient2"))
        }
        let triage2 = if is_critical2 {
          1.0
        } else {
          3.0 + @random.exponential(rng, lambda=0.5)
        }
        @process.Timeout(duration=triage2, next=fn() {
          ignore(patient_fsm.fire("triage"))
          ignore(
            beds.request(pid=p.id(), callback=fn() {
              ignore(patient_fsm.fire("admit"))
              wait_times.push(env.now() - arrive2)
              let treat2 = if is_critical2 {
                20.0 + @random.exponential(rng, lambda=0.1)
              } else {
                10.0 + @random.exponential(rng, lambda=0.2)
              }
              let treat_start2 = env.now()
              ignore(
                env.schedule(time=env.now() + treat2, callback=fn() {
                  ignore(patient_fsm.fire("discharge"))
                  treatment_times.push(env.now() - treat_start2)
                  ignore(bus.publish("discharged", "patient2"))
                  beds.release()
                }),
              )
            }),
          )
          // 患者 3
          total_patients = total_patients + 1
          let arrive3 = env.now()
          let is_critical3 = @random.uniform(rng, min=0.0, max=1.0) < 0.2
          if is_critical3 {
            ignore(bus.publish("critical_alert", "patient3"))
          }
          let triage3 = if is_critical3 {
            1.0
          } else {
            3.0 + @random.exponential(rng, lambda=0.5)
          }
          @process.Timeout(duration=triage3, next=fn() {
            ignore(patient_fsm.fire("triage"))
            ignore(
              beds.request(pid=p.id(), callback=fn() {
                ignore(patient_fsm.fire("admit"))
                wait_times.push(env.now() - arrive3)
                let treat3 = if is_critical3 {
                  20.0 + @random.exponential(rng, lambda=0.1)
                } else {
                  10.0 + @random.exponential(rng, lambda=0.2)
                }
                let treat_start3 = env.now()
                ignore(
                  env.schedule(time=env.now() + treat3, callback=fn() {
                    ignore(patient_fsm.fire("discharge"))
                    treatment_times.push(env.now() - treat_start3)
                    ignore(bus.publish("discharged", "patient3"))
                    beds.release()
                  }),
                )
              }),
            )
            // 患者 4
            total_patients = total_patients + 1
            let arrive4 = env.now()
            let is_critical4 = @random.uniform(rng, min=0.0, max=1.0) < 0.2
            if is_critical4 {
              ignore(bus.publish("critical_alert", "patient4"))
            }
            let triage4 = if is_critical4 {
              1.0
            } else {
              3.0 + @random.exponential(rng, lambda=0.5)
            }
            @process.Timeout(duration=triage4, next=fn() {
              ignore(patient_fsm.fire("triage"))
              ignore(
                beds.request(pid=p.id(), callback=fn() {
                  ignore(patient_fsm.fire("admit"))
                  wait_times.push(env.now() - arrive4)
                  let treat4 = if is_critical4 {
                    20.0 + @random.exponential(rng, lambda=0.1)
                  } else {
                    10.0 + @random.exponential(rng, lambda=0.2)
                  }
                  let treat_start4 = env.now()
                  ignore(
                    env.schedule(time=env.now() + treat4, callback=fn() {
                      ignore(patient_fsm.fire("discharge"))
                      treatment_times.push(env.now() - treat_start4)
                      ignore(bus.publish("discharged", "patient4"))
                      beds.release()
                    }),
                  )
                }),
              )
              @process.Done
            })
          })
        })
      })
    }),
  )

  env.run()

  println("Hospital ER Simulation")
  println("=======================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Patient Statistics:")
  println("  Total arrivals:       \{total_patients}")
  println("  Critical patients:    \{critical_patients}")
  println("  Treated & discharged: \{treated_patients}")
  println("")
  if wait_times.length() > 0 {
    let ws = @stats.summary(wait_times)
    println("Wait Time (triage + bed):")
    println("  Count:  \{wait_times.length()}")
    println("  Mean:   \{ws.mean}")
    println("  StdDev: \{ws.stddev}")
    println("  Min:    \{ws.min}")
    println("  Max:    \{ws.max}")
  }
  println("")
  if treatment_times.length() > 0 {
    let ts = @stats.summary(treatment_times)
    println("Treatment Time:")
    println("  Count:  \{treatment_times.length()}")
    println("  Mean:   \{ts.mean}")
    println("  StdDev: \{ts.stddev}")
    println("  Min:    \{ts.min}")
    println("  Max:    \{ts.max}")
  }
  println("")
  println("Patient FSM:")
  println("  Current state: \{patient_fsm.current()}")
  println("  Transitions:   \{patient_fsm.transition_count()}")
  println("  History:       \{patient_fsm.history().length()} states")
  println("")
  println("Event Bus:")
  println("  Topics: \{bus.topics().length()}")
  println("  Total subscribers: \{bus.total_subscribers()}")
}
