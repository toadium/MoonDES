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
/// 水工建筑物定义
struct HydraulicStruct {
  name : String         // 构筑物名称
  struct_type : String  // 类型: 矩形/圆形/渠道
  length : Double       // 长度/直径 (m)
  width : Double        // 宽度 (m), 圆形为0
  depth : Double        // 有效水深 (m)
  units : Int           // 并联数量
  design_flow : Double  // 设计流量 (m3/h)
  status : String       // 运行状态
} derive(Show)

///|
/// 计算有效容积 (m3)
fn hyd_volume(s : HydraulicStruct) -> Double {
  if s.width > 0.0 {
    s.length * s.width * s.depth * s.units.to_double()
  } else {
    // 圆形: π * r^2 * h
    3.14159 * (s.length / 2.0) * (s.length / 2.0) * s.depth * s.units.to_double()
  }
}

///|
/// 计算水力停留时间 HRT (小时)
fn hyd_hrt(s : HydraulicStruct) -> Double {
  let vol = hyd_volume(s)
  if s.design_flow > 0.0 {
    vol / s.design_flow
  } else {
    0.0
  }
}

///|
/// 计算表面负荷 (m3/m2/h), 仅沉淀池
fn hyd_surface_load(s : HydraulicStruct) -> Double {
  let area = if s.width > 0.0 {
    s.length * s.width * s.units.to_double()
  } else {
    3.14159 * (s.length / 2.0) * (s.length / 2.0) * s.units.to_double()
  }
  if area > 0.0 {
    s.design_flow / area
  } else {
    0.0
  }
}

///|
/// 水工建筑物列表
fn hyd_structures() -> Array[HydraulicStruct] {
  [
  { name: "进水泵房", struct_type: "矩形", length: 12.0, width: 6.0, depth: 5.0, units: 1, design_flow: 500.0, status: "运行" },
  { name: "粗格栅间", struct_type: "渠道", length: 8.0, width: 1.2, depth: 2.0, units: 2, design_flow: 500.0, status: "运行" },
  { name: "细格栅间", struct_type: "渠道", length: 8.0, width: 1.0, depth: 2.0, units: 2, design_flow: 500.0, status: "运行" },
  { name: "曝气沉砂池", struct_type: "矩形", length: 12.0, width: 3.0, depth: 3.5, units: 2, design_flow: 500.0, status: "运行" },
  { name: "初沉池", struct_type: "圆形", length: 30.0, width: 0.0, depth: 4.0, units: 2, design_flow: 500.0, status: "运行" },
  { name: "曝气池", struct_type: "矩形", length: 40.0, width: 8.0, depth: 6.0, units: 2, design_flow: 500.0, status: "运行" },
  { name: "二沉池", struct_type: "圆形", length: 36.0, width: 0.0, depth: 4.5, units: 2, design_flow: 500.0, status: "运行" },
  { name: "消毒接触池", struct_type: "矩形", length: 20.0, width: 3.0, depth: 3.0, units: 1, design_flow: 500.0, status: "运行" },
  { name: "污泥浓缩池", struct_type: "圆形", length: 8.0, width: 0.0, depth: 5.0, units: 1, design_flow: 20.0, status: "运行" },
  { name: "贮泥池", struct_type: "矩形", length: 6.0, width: 4.0, depth: 4.0, units: 1, design_flow: 15.0, status: "运行" },
  { name: "配水井", struct_type: "圆形", length: 4.0, width: 0.0, depth: 3.0, units: 1, design_flow: 500.0, status: "运行" },
  { name: "巴歇尔计量槽", struct_type: "渠道", length: 3.0, width: 1.5, depth: 1.2, units: 1, design_flow: 500.0, status: "运行" },
  ]
}

///|
/// 构建水工建筑物 JSON
fn hyd_structures_json() -> String {
  let structs = hyd_structures()
  let items : Array[String] = []
  for s in structs {
    let vol = hyd_volume(s)
    let hrt = hyd_hrt(s)
    let load = hyd_surface_load(s)
    let dim = if s.width > 0.0 {
      "\{s.length}m x \{s.width}m x \{s.depth}m"
    } else {
      "D\{s.length}m x H\{s.depth}m"
    }
    let name_j = s.name.to_json().stringify()
    let type_j = s.struct_type.to_json().stringify()
    let dim_j = dim.to_json().stringify()
    let status_j = s.status.to_json().stringify()
    let vol_str = vol.to_string()
    let hrt_str = hrt.to_string()
    let load_str = load.to_string()
    let flow_str = s.design_flow.to_string()
    let units_str = s.units.to_string()
    items.push("{\"name\":\{name_j},\"type\":\{type_j},\"dim\":\{dim_j},\"volume\":\{vol_str},\"hrt\":\{hrt_str},\"load\":\{load_str},\"flow\":\{flow_str},\"units\":\{units_str},\"status\":\{status_j}}")
  }
  "[\{items.join(", ")}]"
}

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
  @simbuf.println("")
  @simbuf.println("水工建筑物参数:")
  @simbuf.println("----------------------------------------")
  let structs = hyd_structures()
  for s in structs {
    let vol = hyd_volume(s)
    let hrt = hyd_hrt(s)
    let load = hyd_surface_load(s)
    let dim = if s.width > 0.0 {
      "\{s.length}m x \{s.width}m x \{s.depth}m"
    } else {
      "D\{s.length}m x H\{s.depth}m"
    }
    @simbuf.println("  \{s.name} [\{s.struct_type} x\{s.units}]")
    @simbuf.println("    尺寸: \{dim}")
    @simbuf.println("    容积: \{vol} m3")
    @simbuf.println("    HRT:  \{hrt} h")
    @simbuf.println("    表面负荷: \{load} m3/m2/h")
    @simbuf.println("    状态: \{s.status}")
  }
  @simbuf.to_string()
}

///|
let mermaid_chart : String = "flowchart TB\n    IN[进水<br/>COD 350mg/L] --> S1[格栅<br/>拦截杂物]\n    S1 --> S2[沉砂<br/>去除砂粒]\n    S2 --> S3[初沉<br/>SS沉降 60%]\n    S3 --> S4[曝气生化<br/>活性污泥 A2/O]\n    S4 --> S5[二沉<br/>泥水分离]\n    S5 --> S6[消毒<br/>紫外线+次氯酸钠]\n    S6 --> OUT[排放<br/>COD<=50 BOD<=10]\n    S4 -.->|污泥回流| S3\n    S5 -.->|剩余污泥| TH[污泥脱水]\n    M1[水质监测点] -.-> S3\n    M2[水质监测点] -.-> S5\n    M3[水质监测点] -.-> S6\n    AI[AI 监控中心<br/>实时预测+告警] -.-> M1\n    AI -.-> M2\n    AI -.-> M3\n    style IN fill:#1565c0,color:#fff\n    style S4 fill:#ff9800,color:#fff\n    style OUT fill:#4caf50,color:#fff\n    style AI fill:#9c27b0,color:#fff\n    style M1 fill:#00bcd4,color:#fff\n    style M2 fill:#00bcd4,color:#fff\n    style M3 fill:#00bcd4,color:#fff\n    style TH fill:#795548,color:#fff"

///|
fn build_response(output : String) -> String {
  let oj = output.to_json().stringify()
  let mj = mermaid_chart.to_json().stringify()
  let sj = hyd_structures_json()
  "{\"success\":true,\"output\":\{oj},\"mermaid\":\{mj},\"structures\":\{sj},\"name\":\"sewage_treatment\"}"
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
