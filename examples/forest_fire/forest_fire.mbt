///|
/// 示例：森林火灾扩散仿真
///
/// 模拟森林火灾在 2D 网格上的扩散过程。
///
/// - Grid2D 森林网格（20x20，每个格子：Tree/Burning/Empty）
/// - CA 火势传播规则（Burning→邻居Tree有概率点燃→Burning→Empty）
/// - FSM 火警等级：Normal→Watch→Warning→Critical→Contained
/// - EventBus 火势蔓延/扑灭事件
/// - Process 火灾传播动力学
/// - Random 点火概率/风向影响
/// - Stats 燃烧面积/扩散速度统计
///
/// 运行：moon run ./examples/forest_fire --target wasm
fn main {
  let env = @core.new_env(until=100.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 森林网格 20x20
  let grid_w = 20
  let grid_h = 20
  let forest = @grid2d.new_grid2d(width=grid_w, height=grid_h, default="Tree")

  // 随机生成一些空地（10% 概率）
  for y in 0..<grid_h {
    for x in 0..<grid_w {
      let r = @random.uniform(rng, min=0.0, max=1.0)
      if r < 0.1 {
        forest.set(x, y, "Empty")
      }
    }
  }

  // 中心点火
  let cx = grid_w / 2
  let cy = grid_h / 2
  forest.set(cx, cy, "Burning")

  // 火警等级 FSM
  let fire_fsm = @fsm.new_state_machine(initial="Normal", transitions=[
    @fsm.transition(from="Normal", to="Watch", on="escalate"),
    @fsm.transition(from="Watch", to="Warning", on="escalate"),
    @fsm.transition(from="Warning", to="Critical", on="escalate"),
    @fsm.transition(from="Critical", to="Contained", on="contain"),
    @fsm.transition(from="Warning", to="Contained", on="contain"),
    @fsm.transition(from="Watch", to="Contained", on="contain"),
  ])

  // 统计
  let mut total_burned = 0
  let mut peak_burning = 0
  let burn_timeline : Array[Double] = []
  let area_history : Array[Int] = []

  ignore(bus.subscribe("spread", fn(_data) { total_burned = total_burned + 1 }))

  let fsm_ref : Array[@fsm.StateMachine] = []
  fsm_ref.push(fire_fsm)

  // CA 火势传播规则
  // Tree + 邻居有 Burning → 概率点燃
  // Burning → Empty（烧完）
  // Empty → Empty
  let fire_rule = fn(g : @grid2d.Grid2D, x : Int, y : Int) -> String {
    let current = g.get(x, y)
    match current {
      "Empty" => "Empty"
      "Burning" => "Empty" // 烧完变空地
      "Tree" => {
        // 检查 Moore 邻域中有多少个 Burning
        let nbrs = g.neighbors_moore(x, y)
        let burning_count = nbrs.count_if(fn(v) { v == "Burning" })
        if burning_count > 0 {
          // 燃烧概率：基础 0.4 + 每个额外火源 0.1
          let prob = 0.4 + burning_count.to_double() * 0.1
          let r = @random.uniform(rng, min=0.0, max=1.0)
          if r < prob {
            "Burning"
          } else {
            "Tree"
          }
        } else {
          "Tree"
        }
      }
      _ => current
    }
  }

  let ca = @ca.new_ca(grid=forest, rule=fire_rule)

  // 火灾传播进程
  ignore(
    @process.process(env, name="fire_spread", behavior=fn(_p) {
      // 用 env.schedule 驱动每步传播
      let run_ref : Array[(Int) -> Unit] = []
      run_ref.push(fn(step : Int) {
        if step >= 40 {
          return
        }
        ignore(
          env.schedule(time=env.now() + 2.0, callback=fn() {
            // CA 演化一步
            ca.step()
            // 统计当前燃烧数
            let burning = ca.count_value("Burning")
            // 记录燃烧事件
            if burning > 0 {
              for y in 0..<grid_h {
                for x in 0..<grid_w {
                  if ca.current_grid().get(x, y) == "Burning" {
                    ignore(bus.publish("spread", "(\{x},\{y})"))
                  }
                }
              }
              burn_timeline.push(env.now())
            }
            area_history.push(burning)
            if burning > peak_burning {
              peak_burning = burning
            }
            // 火警等级升级
            if burning >= 20 && fsm_ref[0].current() == "Warning" {
              ignore(fsm_ref[0].fire("escalate"))
            } else if burning >= 10 && fsm_ref[0].current() == "Watch" {
              ignore(fsm_ref[0].fire("escalate"))
            } else if burning >= 3 && fsm_ref[0].current() == "Normal" {
              ignore(fsm_ref[0].fire("escalate"))
            }
            // 火灭了
            if burning == 0 && fsm_ref[0].current() != "Contained" && step > 2 {
              ignore(fsm_ref[0].fire("contain"))
            }
            // 调度下一步
            run_ref[0](step + 1)
          }),
        )
      })
      run_ref[0](0)
      @process.Done
    }),
  )

  env.run()

  // 最终统计
  let final_trees = ca.count_value("Tree")
  let final_empties = ca.count_value("Empty")
  let initial_trees = grid_w * grid_h - forest.count_value("Empty")

  // 输出
  println("Forest Fire Spread Simulation")
  println("=============================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Forest Grid: \{grid_w}x\{grid_h} (\{grid_w * grid_h} cells)")
  println("Initial ignition: (\{cx}, \{cy})")
  println("")
  println("Fire Alert FSM:")
  println("  Final phase: \{fire_fsm.current()}")
  println("  Transitions: \{fire_fsm.transition_count()}")
  println("")
  println("Final State Distribution:")
  println("  Trees:  \{final_trees}")
  println("  Burned: \{final_empties} (includes pre-existing empty)")
  println("  Total burned (cumulative): \{total_burned}")
  println("  Peak concurrent fires:    \{peak_burning}")
  let burn_rate = total_burned.to_double() / initial_trees.to_double() * 100.0
  println("  Burn rate:                \{burn_rate}%")
  println("")
  if burn_timeline.length() > 0 {
    let ts = @stats.summary(burn_timeline)
    println("Burn Timeline Statistics:")
    println("  Count:  \{burn_timeline.length()}")
    println("  Mean:   \{ts.mean}")
    println("  StdDev: \{ts.stddev}")
    println("  Min:    \{ts.min}")
    println("  Max:    \{ts.max}")
  }
  println("")
  println("Area History (burning cells per step):")
  for i in 0..<area_history.length() {
    let bar_len = area_history[i]
    let mut bar = ""
    for _ in 0..<bar_len {
      bar += "#"
    }
    if bar.length() > 60 {
      bar = bar[:60].to_owned() + "..."
    }
    println("  Step \{i}: \{area_history[i]} \{bar}")
  }
  println("")
  println("Final Forest Grid (T=Tree, B=Burning, .=Empty):")
  let g = ca.current_grid()
  for y in 0..<grid_h {
    let mut row = "  "
    for x in 0..<grid_w {
      let v = g.get(x, y)
      let ch = match v {
        "Tree" => "T"
        "Burning" => "B"
        "Empty" => "."
        _ => "?"
      }
      row += ch
    }
    println(row)
  }
  println("")
  println("Event Bus:")
  println("  Topics: \{bus.topics().length()}")
  println("  Subscribers: \{bus.total_subscribers()}")
}
