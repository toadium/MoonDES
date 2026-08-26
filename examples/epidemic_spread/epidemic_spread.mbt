///|
/// 示例：传染病传播仿真（SIR 模型在接触网络上）
///
/// 模拟传染病在人群中的传播过程。
///
/// - Graph 构建接触网络（节点=人，边=接触关系）
/// - MarkovChain 个体状态转移 S→E→I→R（概率驱动）
/// - FSM 疫情阶段：Contained→Outbreak→Epidemic→Contained
/// - EventBus 爆发告警/感染事件
/// - Process 感染传播动力学
/// - Random 传播概率/潜伏期
/// - Stats 感染统计/传播速度
///
/// 运行：moon run ./examples/epidemic_spread --target wasm
pub fn run() -> String {
  @simbuf.clear()
  let env = @core.new_env(until=200.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 构建接触网络：20 人，多个社群
  let contact_net = @graph.new_graph()
  // 社群 A（家庭）
  contact_net.add_edge("P01", "P02")
  contact_net.add_edge("P01", "P03")
  contact_net.add_edge("P02", "P03")
  contact_net.add_edge("P03", "P04")
  // 社群 B（学校）
  contact_net.add_edge("P04", "P05")
  contact_net.add_edge("P05", "P06")
  contact_net.add_edge("P05", "P07")
  contact_net.add_edge("P06", "P07")
  contact_net.add_edge("P06", "P08")
  contact_net.add_edge("P07", "P08")
  contact_net.add_edge("P08", "P09")
  // 社群 C（工作）
  contact_net.add_edge("P09", "P10")
  contact_net.add_edge("P10", "P11")
  contact_net.add_edge("P10", "P12")
  contact_net.add_edge("P11", "P12")
  contact_net.add_edge("P11", "P13")
  // 社群 D（社区）
  contact_net.add_edge("P13", "P14")
  contact_net.add_edge("P14", "P15")
  contact_net.add_edge("P14", "P16")
  contact_net.add_edge("P15", "P16")
  contact_net.add_edge("P15", "P17")
  // 跨社群连接
  contact_net.add_edge("P04", "P09")
  contact_net.add_edge("P08", "P13")
  contact_net.add_edge("P12", "P17")
  contact_net.add_edge("P02", "P18")
  contact_net.add_edge("P18", "P19")
  contact_net.add_edge("P19", "P20")
  contact_net.add_edge("P17", "P20")

  // 个体状态 Markov 链：S→E→I→R
  let make_sir_chain = fn() {
    let mc = @markov.new_markov_chain(initial="S", rng~)
    mc.add_transition("S", "S", 0.85)
    mc.add_transition("S", "E", 0.15)
    mc.add_transition("E", "E", 0.3)
    mc.add_transition("E", "I", 0.7)
    mc.add_transition("I", "I", 0.2)
    mc.add_transition("I", "R", 0.8)
    mc.add_transition("R", "R", 1.0)
    mc
  }

  let people = contact_net.nodes()
  let person_chains : Map[String, @markov.MarkovChain] = Map([])
  for person in people {
    person_chains[person] = make_sir_chain()
  }

  // 疫情阶段 FSM
  let epidemic_fsm = @fsm.new_state_machine(initial="Contained", transitions=[
    @fsm.transition(from="Contained", to="Outbreak", on="outbreak"),
    @fsm.transition(from="Outbreak", to="Epidemic", on="spread"),
    @fsm.transition(from="Epidemic", to="Contained", on="contained"),
    @fsm.transition(from="Outbreak", to="Contained", on="contained"),
  ])

  // 统计
  let mut total_infected = 0
  let mut total_recovered = 0
  let mut peak_infected = 0
  let mut current_infected = 0
  let infection_timeline : Array[Double] = []

  ignore(
    bus.subscribe("infection", fn(_data) {
      total_infected = total_infected + 1
      current_infected = current_infected + 1
      if current_infected > peak_infected {
        peak_infected = current_infected
      }
    }),
  )
  ignore(
    bus.subscribe("recovery", fn(_data) {
      total_recovered = total_recovered + 1
      current_infected = current_infected - 1
    }),
  )

  let fsm_ref : Array[@fsm.StateMachine] = []
  fsm_ref.push(epidemic_fsm)

  // 用 env.schedule 驱动传播步骤（数组持有以支持递归）
  let run_ref : Array[(Int) -> Unit] = []
  run_ref.push(fn(step : Int) {
    if step >= 30 {
      return
    }
    ignore(
      env.schedule(time=env.now() + 5.0, callback=fn() {
        // 感染者向邻居传播
        for person in people {
          if person_chains[person].current() == "I" {
            let contacts = contact_net.neighbors(person)
            for contact in contacts {
              if person_chains[contact].current() == "S" {
                let prob = @random.uniform(rng, min=0.0, max=1.0)
                if prob < 0.3 {
                  ignore(person_chains[contact].next_state())
                }
              }
            }
          }
        }
        // 状态更新 E→I, I→R
        for person in people {
          let state = person_chains[person].current()
          if state == "E" {
            let prob = @random.uniform(rng, min=0.0, max=1.0)
            if prob < 0.7 {
              ignore(person_chains[person].next_state())
              if person_chains[person].current() == "I" {
                ignore(bus.publish("infection", person))
                infection_timeline.push(env.now())
              }
            }
          } else if state == "I" {
            let prob = @random.uniform(rng, min=0.0, max=1.0)
            if prob < 0.4 {
              ignore(person_chains[person].next_state())
              if person_chains[person].current() == "R" {
                ignore(bus.publish("recovery", person))
              }
            }
          }
        }
        // 检查疫情阶段
        let mut inf_count = 0
        for person in people {
          if person_chains[person].current() == "I" {
            inf_count = inf_count + 1
          }
        }
        if inf_count >= 5 && fsm_ref[0].current() == "Outbreak" {
          ignore(fsm_ref[0].fire("spread"))
        }
        if inf_count == 0 && fsm_ref[0].current() != "Contained" {
          ignore(fsm_ref[0].fire("contained"))
        }
        // 递归调度下一步
        run_ref[0](step + 1)
      }),
    )
  })

  // 感染传播进程：P03 是零号病人
  ignore(
    @process.process(env, name="epidemic", behavior=fn(_p) {
      // 初始感染
      ignore(person_chains["P03"].next_state()) // S→E
      ignore(person_chains["P03"].next_state()) // E→I
      ignore(bus.publish("infection", "P03"))
      infection_timeline.push(env.now())
      ignore(fsm_ref[0].fire("outbreak"))
      // 启动传播步骤
      run_ref[0](0)
      @process.Done
    }),
  )

  env.run()

  // 统计最终状态
  let mut final_s = 0
  let mut final_e = 0
  let mut final_i = 0
  let mut final_r = 0
  for person in people {
    let state = person_chains[person].current()
    match state {
      "S" => final_s = final_s + 1
      "E" => final_e = final_e + 1
      "I" => final_i = final_i + 1
      "R" => final_r = final_r + 1
      _ => ()
    }
  }

  // 输出
  @simbuf.println("Epidemic Spread Simulation (SIR Model)")
  @simbuf.println("======================================")
  @simbuf.println("Simulation time: \{env.now()}")
  @simbuf.println("Events processed: \{env.event_count()}")
  @simbuf.println("")
  @simbuf.println("Contact Network:")
  @simbuf.println("  Population: \{contact_net.node_count()}")
  @simbuf.println("  Contacts (edges): \{contact_net.edge_count()}")
  @simbuf.println("  Components: \{contact_net.connected_components().length()}")
  @simbuf.println("")
  @simbuf.println("Epidemic FSM:")
  @simbuf.println("  Final phase: \{epidemic_fsm.current()}")
  @simbuf.println("  Transitions: \{epidemic_fsm.transition_count()}")
  @simbuf.println("")
  @simbuf.println("Final State Distribution:")
  @simbuf.println("  Susceptible (S): \{final_s}")
  @simbuf.println("  Exposed (E):     \{final_e}")
  @simbuf.println("  Infected (I):    \{final_i}")
  @simbuf.println("  Recovered (R):   \{final_r}")
  @simbuf.println("")
  @simbuf.println("Epidemic Statistics:")
  @simbuf.println("  Total infected (cumulative): \{total_infected}")
  @simbuf.println("  Total recovered:             \{total_recovered}")
  @simbuf.println("  Peak concurrent infections:   \{peak_infected}")
  let attack_rate = total_infected.to_double() /
    contact_net.node_count().to_double() *
    100.0
  @simbuf.println("  Attack rate:                 \{attack_rate}%")
  @simbuf.println("")
  if infection_timeline.length() > 0 {
    let ts = @stats.summary(infection_timeline)
    @simbuf.println("Infection Timeline Statistics:")
    @simbuf.println("  Count:  \{infection_timeline.length()}")
    @simbuf.println("  Mean:   \{ts.mean}")
    @simbuf.println("  StdDev: \{ts.stddev}")
    @simbuf.println("  Min:    \{ts.min}")
    @simbuf.println("  Max:    \{ts.max}")
  }
  @simbuf.println("")
  @simbuf.println("Per-Person Status:")
  for person in people {
    let state = person_chains[person].current()
    let deg = contact_net.degree(person)
    let label = match state {
      "S" => "Susceptible"
      "E" => "Exposed"
      "I" => "Infected"
      "R" => "Recovered"
      _ => "Unknown"
    }
    @simbuf.println("  \{person}: \{label} (contacts=\{deg})")
  }
  @simbuf.println("")
  @simbuf.println("Event Bus:")
  @simbuf.println("  Topics: \{bus.topics().length()}")
  @simbuf.println("  Subscribers: \{bus.total_subscribers()}")
  @simbuf.to_string()
}