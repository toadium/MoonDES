///|
/// 污水处理厂 AI 监控仿真系统 — 后端
/// 基于 MoonDES 离散事件仿真引擎
/// HTTP server on port 8081

///|
fn make_headers(entries : Array[(String, String)]) -> @http.Headers {
  let m : @http.Headers = Map([])
  for entry in entries {
    m[@http.CaseInsensitiveString(entry.0)] = entry.1
  }
  m
}

let json_headers : @http.Headers = make_headers([
  ("Content-Type", "application/json; charset=utf-8"),
  ("Access-Control-Allow-Origin", "*"),
  ("Access-Control-Allow-Methods", "GET, POST, OPTIONS"),
  ("Access-Control-Allow-Headers", "Content-Type"),
])

let html_headers : @http.Headers = make_headers([
  ("Content-Type", "text/html; charset=utf-8"),
])

let text_headers : @http.Headers = make_headers([
  ("Content-Type", "text/plain; charset=utf-8"),
])

///|
/// 污水处理厂仿真
fn run_sewage_sim() -> String {
  @simbuf.clear()
  let env = @core.new_env(until=300.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()
  let plant = @pipeline.new_pipeline()
  plant.add_stage(name="进水", capacity=25, processing_time=1.0)
  plant.add_stage(name="格栅", capacity=20, processing_time=2.0)
  plant.add_stage(name="初沉", capacity=15, processing_time=10.0)
  plant.add_stage(name="曝气生化", capacity=12, processing_time=20.0)
  plant.add_stage(name="二沉", capacity=10, processing_time=12.0)
  plant.add_stage(name="消毒", capacity=15, processing_time=4.0)
  plant.add_stage(name="排放", capacity=30, processing_time=1.0)
  let stage_res : Array[@resource.Resource] = []
  for i in 0..<plant.stage_count() {
    let s = plant.get(i)
    stage_res.push(@resource.new_capacity(name=s.name, capacity=s.capacity))
  }
  let q_fsm = @fsm.new_state_machine(initial="达标", transitions=[
    @fsm.transition(from="达标", to="临界", on="marginal"),
    @fsm.transition(from="临界", to="超标", on="exceed"),
    @fsm.transition(from="超标", to="调节中", on="adjust"),
    @fsm.transition(from="调节中", to="达标", on="restored"),
    @fsm.transition(from="临界", to="达标", on="recovered"),
  ])
  let mut total_inflow = 0
  let mut total_discharged = 0
  let mut exceedance_events = 0
  let treatment_times : Array[Double] = []
  ignore(bus.subscribe("exceedance", fn(_d) { exceedance_events = exceedance_events + 1 }))
  ignore(bus.subscribe("discharged", fn(_d) { total_discharged = total_discharged + 1 }))
  let fsm_ref : Array[@fsm.StateMachine] = []
  fsm_ref.push(q_fsm)

  ignore(@process.process(env, name="sewage_flow_1", behavior=fn(p) {
    total_inflow = total_inflow + 1
    let batch_start = env.now()
    let cod = 50.0 + @random.normal(rng, mean=0.0, std=15.0)
    if cod > 80.0 {
      ignore(fsm_ref[0].fire("exceed"))
      ignore(bus.publish("exceedance", "COD=\{cod}"))
    } else if cod > 60.0 {
      ignore(fsm_ref[0].fire("marginal"))
    }
    let ps = fn(idx : Int, next : () -> @process.ProcessAction) {
      let stage = plant.get(idx)
      ignore(stage_res[idx].request(pid=p.id(), callback=fn() {
        let pt = stage.processing_time + @random.normal(rng, mean=0.0, std=2.0)
        let actual = if pt > 0.0 { pt } else { stage.processing_time }
        ignore(env.schedule(time=env.now() + actual, callback=fn() { stage_res[idx].release() }))
      }))
      @process.Timeout(duration=stage.processing_time + 2.0, next~)
    }
    ps(0, fn() {
      ps(1, fn() {
        ps(2, fn() {
          ps(3, fn() {
            ps(4, fn() {
              ps(5, fn() {
                ps(6, fn() {
                  treatment_times.push(env.now() - batch_start)
                  ignore(bus.publish("discharged", "b1"))
                  if fsm_ref[0].current() == "超标" {
                    ignore(fsm_ref[0].fire("adjust"))
                  } else if fsm_ref[0].current() == "临界" {
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
  }))

  ignore(@process.process(env, name="sewage_flow_2", behavior=fn(p) {
    @process.Timeout(duration=25.0, next=fn() {
      total_inflow = total_inflow + 1
      let batch_start = env.now()
      let ps = fn(idx : Int, next : () -> @process.ProcessAction) {
        let stage = plant.get(idx)
        ignore(stage_res[idx].request(pid=p.id(), callback=fn() {
          let pt = stage.processing_time + @random.normal(rng, mean=0.0, std=2.0)
          let actual = if pt > 0.0 { pt } else { stage.processing_time }
          ignore(env.schedule(time=env.now() + actual, callback=fn() { stage_res[idx].release() }))
        }))
        @process.Timeout(duration=stage.processing_time + 2.0, next~)
      }
      ps(0, fn() {
        ps(1, fn() {
          ps(2, fn() {
            ps(3, fn() {
              ps(4, fn() {
                ps(5, fn() {
                  ps(6, fn() {
                    treatment_times.push(env.now() - batch_start)
                    ignore(bus.publish("discharged", "b2"))
                    @process.Done
                  })
                })
              })
            })
          })
        })
      })
    })
  }))

  env.run()

  @simbuf.println("污水处理厂仿真运行报告")
  @simbuf.println("========================")
  @simbuf.println("仿真时长: \{env.now()}")
  @simbuf.println("事件总数: \{env.event_count()}")
  @simbuf.println("")
  @simbuf.println("工艺流水线:")
  @simbuf.println(plant.to_string())
  @simbuf.println("")
  match plant.bottleneck() {
    Some(idx) => @simbuf.println("瓶颈阶段: \{plant.get(idx).name} (容量=\{plant.get(idx).capacity})")
    None => @simbuf.println("瓶颈阶段: N/A")
  }
  @simbuf.println("")
  @simbuf.println("水质达标状态机:")
  @simbuf.println("  当前状态: \{q_fsm.current()}")
  @simbuf.println("  状态转移: \{q_fsm.transition_count()}")
  @simbuf.println("  历史记录: \{q_fsm.history().length()} 次")
  @simbuf.println("")
  @simbuf.println("运行统计:")
  @simbuf.println("  进水批次:   \{total_inflow}")
  @simbuf.println("  出水批次:   \{total_discharged}")
  @simbuf.println("  超标事件:   \{exceedance_events}")
  @simbuf.println("")
  if treatment_times.length() > 0 {
    let ts = @stats.summary(treatment_times)
    @simbuf.println("处理时间统计:")
    @simbuf.println("  批次数: \{treatment_times.length()}")
    @simbuf.println("  均值:   \{ts.mean}")
    @simbuf.println("  标准差: \{ts.stddev}")
    @simbuf.println("  最小:   \{ts.min}")
    @simbuf.println("  最大:   \{ts.max}")
  }
  @simbuf.println("")
  @simbuf.println("事件总线:")
  @simbuf.println("  主题数:   \{bus.topics().length()}")
  @simbuf.println("  订阅者:   \{bus.total_subscribers()}")
  @simbuf.to_string()
}

///|
let mermaid_chart : String = "flowchart TB\n    IN[进水<br/>COD 350mg/L] --> S1[格栅<br/>拦截杂物]\n    S1 --> S2[沉砂<br/>去除砂粒]\n    S2 --> S3[初沉<br/>SS沉降 60%]\n    S3 --> S4[曝气生化<br/>活性污泥 A2/O]\n    S4 --> S5[二沉<br/>泥水分离]\n    S5 --> S6[消毒<br/>紫外线+次氯酸钠]\n    S6 --> OUT[排放<br/>COD<=50 BOD<=10]\n    S4 -.->|污泥回流| S3\n    S5 -.->|剩余污泥| TH[污泥脱水]\n    M1[水质监测点] -.-> S3\n    M2[水质监测点] -.-> S5\n    M3[水质监测点] -.-> S6\n    AI[AI 监控中心<br/>实时预测+告警] -.-> M1\n    AI -.-> M2\n    AI -.-> M3\n    style IN fill:#1565c0,color:#fff\n    style S4 fill:#ff9800,color:#fff\n    style OUT fill:#4caf50,color:#fff\n    style AI fill:#9c27b0,color:#fff\n    style M1 fill:#00bcd4,color:#fff\n    style M2 fill:#00bcd4,color:#fff\n    style M3 fill:#00bcd4,color:#fff\n    style TH fill:#795548,color:#fff"

///|
fn build_response(output : String) -> String {
  let oj = output.to_json().stringify()
  let mj = mermaid_chart.to_json().stringify()
  "{\"success\":true,\"output\":\{oj},\"mermaid\":\{mj},\"name\":\"sewage_treatment\"}"
}

///|
async fn send_file(conn : @http.ServerConnection, path : String, headers : @http.Headers, error_msg : String) -> Unit {
  let content = try {
    @fs.read_file(path).text()
  } catch {
    _ => {
      conn.send_response(404, "NotFound", extra_headers=text_headers)
      conn.write_string(error_msg)
      conn.end_response()
      return
    }
  }
  conn.send_response(200, "OK", extra_headers=headers)
  conn.write_string(content)
  conn.end_response()
}

///|
async fn main {
  @stdio.stdout.write("污水处理厂 AI 监控仿真系统\n")
  @stdio.stdout.write("============================\n")
  @stdio.stdout.write("Listening on http://127.0.0.1:8081\n")

  let server = @http.Server(@socket.Addr::parse("127.0.0.1:8081")) catch {
    err => { @stdio.stdout.write("Failed: \{err}\n"); return }
  }

  server.run_forever(async fn(request, body, conn) {
    match (request.meth, request.path) {
      (@http.Options, _) => {
        conn.send_response(204, "NoContent", extra_headers=json_headers)
        conn.end_response()
      }
      (@http.Get, "/") =>
        send_file(conn, "sewage_monitor/index.html", html_headers, "Missing index.html")
      (@http.Post, "/api/simulate") => {
        let _raw = try { body.read_all().text() } catch { _ => "" }
        let output = run_sewage_sim()
        let json_str = build_response(output)
        conn.send_response(200, "OK", extra_headers=json_headers)
        conn.write_string(json_str)
        conn.end_response()
      }
      _ => {
        conn.send_response(404, "NotFound", extra_headers=text_headers)
        conn.write_string("Not Found")
        conn.end_response()
      }
    }
  })
}
