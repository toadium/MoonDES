///|
/// 示例：人脉关系网社交网络仿真
///
/// 构建一个社交网络图，模拟信息（如一条新闻/推荐）在网络中的传播。
///
/// - Graph 构建人脉关系网（节点=人，边=关系）
/// - FSM 跟踪人物状态：Uninformed → Informed → Influencer
/// - EventBus 发布信息传播事件
/// - Process 驱动传播动力学
/// - Random 控制传播概率
/// - Stats 统计传播范围、速度、影响力
///
/// 运行：moon run ./examples/social_network --target wasm
fn main {
  let env = @core.new_env(until=100.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 构建人脉关系网
  let network = @graph.new_graph()
  // 社群 1：技术圈
  network.add_edge("Alice", "Bob")
  network.add_edge("Alice", "Carol")
  network.add_edge("Bob", "Dave")
  network.add_edge("Carol", "Dave")
  network.add_edge("Dave", "Eve")
  // 社群 2：市场圈
  network.add_edge("Alice", "Frank")
  network.add_edge("Frank", "Grace")
  network.add_edge("Grace", "Henry")
  network.add_edge("Henry", "Iris")
  // 社群 3：管理圈
  network.add_edge("Alice", "Jack")
  network.add_edge("Jack", "Kate")
  network.add_edge("Kate", "Leo")
  network.add_edge("Leo", "Mia")
  // 跨社群连接
  network.add_edge("Eve", "Frank")
  network.add_edge("Iris", "Jack")

  // 人物状态机：Uninformed → Informed → Influencer
  let make_person_fsm = fn() {
    @fsm.new_state_machine(initial="Uninformed", transitions=[
      @fsm.transition(from="Uninformed", to="Informed", on="inform"),
      @fsm.transition(from="Informed", to="Influencer", on="amplify"),
    ])
  }

  // 为每个人创建 FSM
  let people = network.nodes()
  let person_fsms : Map[String, @fsm.StateMachine] = Map([])
  for person in people {
    person_fsms[person] = make_person_fsm()
  }

  // 统计
  let mut total_informed = 0
  let mut total_influencers = 0
  let inform_times : Array[Double] = []
  let influence_scores : Array[Double] = []

  // 监控
  ignore(
    bus.subscribe("informed", fn(_data) { total_informed = total_informed + 1 }),
  )
  ignore(
    bus.subscribe("influencer", fn(_data) {
      total_influencers = total_influencers + 1
    }),
  )

  // 信息传播进程：从 Alice 开始
  ignore(
    @process.process(env, name="info_spread", behavior=fn(_p) {
      let start_time = env.now()
      ignore(person_fsms["Alice"].fire("inform"))
      ignore(bus.publish("informed", "Alice"))
      inform_times.push(env.now() - start_time)

      // 向好友传播的辅助函数
      let spread_to = fn(
        person : String,
        delay : Double,
        next : () -> @process.ProcessAction,
      ) {
        @process.Timeout(duration=delay, next=fn() {
          if person_fsms[person].current() == "Uninformed" {
            let prob = @random.uniform(rng, min=0.0, max=1.0)
            if prob < 0.8 {
              ignore(person_fsms[person].fire("inform"))
              ignore(bus.publish("informed", person))
              inform_times.push(env.now() - start_time)
              // 二级传播
              let friends = network.neighbors(person)
              for f in friends {
                if person_fsms[f].current() == "Uninformed" {
                  let p2 = @random.uniform(rng, min=0.0, max=1.0)
                  if p2 < 0.4 {
                    let delay2 = @random.exponential(rng, lambda=0.5)
                    ignore(
                      env.schedule(time=env.now() + delay2, callback=fn() {
                        if person_fsms[f].current() == "Uninformed" {
                          ignore(person_fsms[f].fire("inform"))
                          ignore(bus.publish("informed", f))
                          inform_times.push(env.now() - start_time)
                          // 15% 概率成为影响者
                          let p3 = @random.uniform(rng, min=0.0, max=1.0)
                          if p3 < 0.15 {
                            ignore(person_fsms[f].fire("amplify"))
                            ignore(bus.publish("influencer", f))
                            // 三级传播
                            let f3s = network.neighbors(f)
                            for f3 in f3s {
                              if person_fsms[f3].current() == "Uninformed" {
                                let p4 = @random.uniform(rng, min=0.0, max=1.0)
                                if p4 < 0.6 {
                                  let delay3 = @random.exponential(
                                    rng,
                                    lambda=1.0,
                                  )
                                  ignore(
                                    env.schedule(time=env.now() + delay3, callback=fn() {
                                      if person_fsms[f3].current() ==
                                        "Uninformed" {
                                        ignore(person_fsms[f3].fire("inform"))
                                        ignore(bus.publish("informed", f3))
                                        inform_times.push(
                                          env.now() - start_time,
                                        )
                                      }
                                    }),
                                  )
                                }
                              }
                            }
                          }
                        }
                      }),
                    )
                  }
                }
              }
            }
          }
          next()
        })
      }

      // 向 Alice 的好友传播
      let alice_friends = network.neighbors("Alice")
      spread_to(alice_friends[0], @random.exponential(rng, lambda=0.3), fn() {
        spread_to(alice_friends[1], @random.exponential(rng, lambda=0.3), fn() {
          spread_to(alice_friends[2], @random.exponential(rng, lambda=0.3), fn() {
            @process.Done
          })
        })
      })
    }),
  )

  env.run()

  // 计算影响力分数
  for person in people {
    let deg = network.degree(person).to_double()
    let informed_bonus = if person_fsms[person].current() != "Uninformed" {
      2.0
    } else {
      0.0
    }
    influence_scores.push(deg + informed_bonus)
  }

  // 输出
  println("Social Network Simulation")
  println("==========================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Network Topology:")
  println("  Nodes (people): \{network.node_count()}")
  println("  Edges (relationships): \{network.edge_count()}")
  println("  Components: \{network.connected_components().length()}")
  println("")
  println("BFS from Alice (information reach order):")
  let bfs_order = network.bfs("Alice")
  for i in 0..<bfs_order.length() {
    let person = bfs_order[i]
    let deg = network.degree(person)
    let state = person_fsms[person].current()
    let label = if state == "Influencer" {
      " * influencer"
    } else if state == "Informed" {
      " + informed"
    } else {
      " - uninformed"
    }
    println("  [\{i}] \{person} (degree=\{deg})\{label}")
  }
  println("")
  println("Shortest Paths from Alice:")
  for person in people {
    if person != "Alice" {
      match network.shortest_path("Alice", person) {
        Some(path) => {
          let hops = path.length() - 1
          let path_str = path.join(" -> ")
          println("  Alice -> \{person}: \{hops} hops (\{path_str})")
        }
        None => println("  Alice -> \{person}: unreachable")
      }
    }
  }
  println("")
  println("Information Spread Statistics:")
  println("  Total informed:    \{total_informed}")
  println("  Total influencers: \{total_influencers}")
  let reach_rate = total_informed.to_double() /
    network.node_count().to_double() *
    100.0
  println("  Reach rate:        \{reach_rate}%")
  println("")
  if inform_times.length() > 0 {
    let ts = @stats.summary(inform_times)
    println("Inform Time Statistics:")
    println("  Count:  \{inform_times.length()}")
    println("  Mean:   \{ts.mean}")
    println("  StdDev: \{ts.stddev}")
    println("  Min:    \{ts.min}")
    println("  Max:    \{ts.max}")
  }
  println("")
  if influence_scores.length() > 0 {
    let is_stat = @stats.summary(influence_scores)
    println("Influence Score Statistics:")
    println("  Count:  \{influence_scores.length()}")
    println("  Mean:   \{is_stat.mean}")
    println("  StdDev: \{is_stat.stddev}")
    println("  Min:    \{is_stat.min}")
    println("  Max:    \{is_stat.max}")
  }
  println("")
  println("Event Bus:")
  println("  Topics: \{bus.topics().length()}")
  println("  Subscribers: \{bus.total_subscribers()}")
}
