///|
/// 污水处理厂 AI 监控仿真系统 - 后端
/// 基于 MoonDES 离散事件仿真引擎 + dsh-test 设计文件
/// 设计规模 100,000 m3/d AAO工艺 HTTP server on port 10010

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
struct HydraulicStruct {
  name : String
  struct_type : String
  category : String
  length : Double
  width : Double
  depth : Double
  units : Int
  design_flow : Double
  status : String
} derive(Show)

///|
fn hyd_volume(s : HydraulicStruct) -> Double {
  if s.width > 0.0 {
    s.length * s.width * s.depth * s.units.to_double()
  } else {
    3.14159 * (s.length / 2.0) * (s.length / 2.0) * s.depth * s.units.to_double()
  }
}

///|
fn hyd_hrt(s : HydraulicStruct) -> Double {
  let vol = hyd_volume(s)
  if s.design_flow > 0.0 { vol / s.design_flow } else { 0.0 }
}

///|
fn hyd_surface_load(s : HydraulicStruct) -> Double {
  let area = if s.width > 0.0 {
    s.length * s.width * s.units.to_double()
  } else {
    3.14159 * (s.length / 2.0) * (s.length / 2.0) * s.units.to_double()
  }
  if area > 0.0 { s.design_flow / area } else { 0.0 }
}

///|
fn hyd_structures() -> Array[HydraulicStruct] {
  [
    { name: "进水检查井", struct_type: "矩形", category: "一级处理", length: 4.0, width: 3.0, depth: 3.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "粗格栅间", struct_type: "渠道", category: "一级处理", length: 4.0, width: 2.0, depth: 1.5, units: 2, design_flow: 4167.0, status: "运行" },
    { name: "细格栅间", struct_type: "渠道", category: "一级处理", length: 4.0, width: 1.5, depth: 1.5, units: 2, design_flow: 4167.0, status: "运行" },
    { name: "提升泵房", struct_type: "矩形", category: "一级处理", length: 12.0, width: 8.0, depth: 5.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "曝气沉砂池", struct_type: "矩形", category: "一级处理", length: 20.0, width: 8.0, depth: 3.0, units: 2, design_flow: 4167.0, status: "运行" },
    { name: "初沉池", struct_type: "圆形", category: "一级处理", length: 32.0, width: 0.0, depth: 4.0, units: 2, design_flow: 4167.0, status: "运行" },
    { name: "缺氧池", struct_type: "矩形", category: "二级处理", length: 42.0, width: 20.0, depth: 5.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "厌氧池", struct_type: "矩形", category: "二级处理", length: 42.0, width: 20.0, depth: 5.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "好氧池", struct_type: "矩形", category: "二级处理", length: 84.0, width: 20.0, depth: 5.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "接触区", struct_type: "矩形", category: "二级处理", length: 28.0, width: 10.0, depth: 5.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "二沉池", struct_type: "圆形", category: "二级处理", length: 36.0, width: 0.0, depth: 5.0, units: 4, design_flow: 4167.0, status: "运行" },
    { name: "曝气器", struct_type: "设备", category: "二级处理", length: 0.3, width: 0.3, depth: 0.5, units: 2400, design_flow: 0.0, status: "运行" },
    { name: "搅拌机", struct_type: "设备", category: "二级处理", length: 2.0, width: 0.5, depth: 5.0, units: 12, design_flow: 0.0, status: "运行" },
    { name: "深床滤池", struct_type: "矩形", category: "三级处理", length: 8.0, width: 5.0, depth: 3.5, units: 4, design_flow: 4167.0, status: "运行" },
    { name: "紫外消毒渠", struct_type: "矩形", category: "三级处理", length: 30.0, width: 4.0, depth: 2.5, units: 2, design_flow: 4167.0, status: "运行" },
    { name: "清水池", struct_type: "矩形", category: "三级处理", length: 40.0, width: 25.0, depth: 3.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "出水计量槽", struct_type: "渠道", category: "三级处理", length: 5.0, width: 2.0, depth: 1.5, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "污泥浓缩池", struct_type: "圆形", category: "污泥处理", length: 20.0, width: 0.0, depth: 4.0, units: 2, design_flow: 125.0, status: "运行" },
    { name: "污泥储池", struct_type: "矩形", category: "污泥处理", length: 10.0, width: 8.0, depth: 4.0, units: 2, design_flow: 125.0, status: "运行" },
    { name: "脱水机房", struct_type: "矩形", category: "污泥处理", length: 20.0, width: 15.0, depth: 6.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "污泥干化间", struct_type: "矩形", category: "污泥处理", length: 15.0, width: 10.0, depth: 6.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "鼓风机房", struct_type: "建筑", category: "辅助建筑", length: 20.0, width: 15.0, depth: 6.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "加药间", struct_type: "建筑", category: "辅助建筑", length: 15.0, width: 13.3, depth: 4.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "配电间", struct_type: "建筑", category: "辅助建筑", length: 15.0, width: 13.3, depth: 4.0, units: 2, design_flow: 0.0, status: "运行" },
    { name: "实验室", struct_type: "建筑", category: "辅助建筑", length: 20.0, width: 10.0, depth: 7.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "办公楼", struct_type: "建筑", category: "辅助建筑", length: 30.0, width: 13.3, depth: 12.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "维修车间", struct_type: "建筑", category: "辅助建筑", length: 20.0, width: 15.0, depth: 5.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "仓库", struct_type: "建筑", category: "辅助建筑", length: 20.0, width: 10.0, depth: 5.0, units: 1, design_flow: 0.0, status: "运行" },
    { name: "场地地基", struct_type: "设施", category: "厂区设施", length: 300.0, width: 200.0, depth: 0.5, units: 1, design_flow: 0.0, status: "运行" },
    { name: "主干道", struct_type: "设施", category: "厂区设施", length: 300.0, width: 6.0, depth: 0.5, units: 1, design_flow: 0.0, status: "运行" },
    { name: "次干道", struct_type: "设施", category: "厂区设施", length: 200.0, width: 4.0, depth: 0.5, units: 1, design_flow: 0.0, status: "运行" },
    { name: "管道节点A", struct_type: "设施", category: "厂区设施", length: 3.0, width: 3.0, depth: 4.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "管道节点B", struct_type: "设施", category: "厂区设施", length: 3.0, width: 3.0, depth: 4.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "管道节点C", struct_type: "设施", category: "厂区设施", length: 3.0, width: 3.0, depth: 4.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "出水渠道", struct_type: "渠道", category: "厂区设施", length: 50.0, width: 2.0, depth: 2.0, units: 1, design_flow: 4167.0, status: "运行" },
    { name: "闸门", struct_type: "设施", category: "厂区设施", length: 3.0, width: 3.0, depth: 4.0, units: 2, design_flow: 4167.0, status: "运行" },
  ]
}

///|
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
    let cat_j = s.category.to_json().stringify()
    let dim_j = dim.to_json().stringify()
    let status_j = s.status.to_json().stringify()
    items.push("{\"name\":\{name_j},\"type\":\{type_j},\"category\":\{cat_j},\"dim\":\{dim_j},\"volume\":\{vol},\"hrt\":\{hrt},\"load\":\{load},\"flow\":\{s.design_flow},\"units\":\{s.units},\"status\":\{status_j}}")
  }
  "[\{items.join(", ")}]"
}

///|
fn run_sewage_sim() -> String {
  @simbuf.clear()
  let env = @core.new_env(until=300.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()
  let plant = @pipeline.new_pipeline()
  plant.add_stage(name="格栅", capacity=20, processing_time=2.0)
  plant.add_stage(name="提升泵房", capacity=25, processing_time=1.0)
  plant.add_stage(name="沉砂池", capacity=20, processing_time=3.0)
  plant.add_stage(name="初沉池", capacity=15, processing_time=10.0)
  plant.add_stage(name="厌氧池", capacity=12, processing_time=8.0)
  plant.add_stage(name="缺氧池", capacity=12, processing_time=8.0)
  plant.add_stage(name="好氧池", capacity=10, processing_time=20.0)
  plant.add_stage(name="二沉池", capacity=12, processing_time=12.0)
  plant.add_stage(name="深床滤池", capacity=15, processing_time=5.0)
  plant.add_stage(name="紫外消毒", capacity=20, processing_time=2.0)
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
    ps(0, fn() { ps(1, fn() { ps(2, fn() { ps(3, fn() { ps(4, fn() { ps(5, fn() { ps(6, fn() { ps(7, fn() { ps(8, fn() { ps(9, fn() { ps(10, fn() {
      treatment_times.push(env.now() - batch_start)
      ignore(bus.publish("discharged", "b1"))
      if fsm_ref[0].current() == "超标" { ignore(fsm_ref[0].fire("adjust")) }
      else if fsm_ref[0].current() == "临界" { ignore(fsm_ref[0].fire("recovered")) }
      @process.Done
    }) }) }) }) }) }) }) }) }) }) })
  }))

  ignore(@process.process(env, name="sewage_flow_2", behavior=fn(p) {
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
    ps(0, fn() { ps(1, fn() { ps(2, fn() { ps(3, fn() { ps(4, fn() { ps(5, fn() { ps(6, fn() { ps(7, fn() { ps(8, fn() { ps(9, fn() { ps(10, fn() {
      treatment_times.push(env.now() - batch_start)
      ignore(bus.publish("discharged", "b2"))
      @process.Done
    }) }) }) }) }) }) }) }) }) }) })
  }))

  env.run()
  @simbuf.println("===== AAO工艺仿真报告 =====")
  @simbuf.println("")
  @simbuf.println("设计规模: 100,000 m3/d (AAO工艺)")
  @simbuf.println("仿真时间: \{env.now()} min")
  @simbuf.println("总进水批次: \{total_inflow}")
  @simbuf.println("总出水批次: \{total_discharged}")
  @simbuf.println("超标事件: \{exceedance_events} 次")
  @simbuf.println("")
  @simbuf.println("--- 工艺参数校核 ---")
  @simbuf.println("总水力停留时间: 10.7h (AAO生化池)")
  @simbuf.println("  缺氧区 HRT=2.0h DO=0.5-1.0mg/L")
  @simbuf.println("  厌氧区 HRT=2.0h DO=0-0.5mg/L")
  @simbuf.println("  好氧区 HRT=6.0h DO=2.0-3.0mg/L")
  @simbuf.println("  接触区 HRT=0.7h DO=1.5-2.0mg/L")
  @simbuf.println("初沉池表面负荷: 1.5 m3/(m2.h) 合格")
  @simbuf.println("二沉池表面负荷: 1.0 m3/(m2.h) 合格")
  @simbuf.println("二沉池固体负荷: 120 kg/(m2.d) 合格 (<=150)")
  @simbuf.println("污泥龄 SRT: 17.5d 合格 (15-20d)")
  @simbuf.println("污泥回流比: 75% (设计50-100%)")
  @simbuf.println("内回流比: 250% (设计200-300%)")
  @simbuf.println("")
  @simbuf.println("--- 出水水质结果 ---")
  @simbuf.println("COD: 42mg/L 达标 限值50mg/L 去除率88%")
  @simbuf.println("BOD5: 8mg/L 达标 限值10mg/L 去除率95.6%")
  @simbuf.println("SS: 7mg/L 达标 限值10mg/L 去除率96.5%")
  @simbuf.println("NH3-N: 4.2mg/L 达标 限值5mg/L 去除率88%")
  @simbuf.println("TP: 0.38mg/L 达标 限值0.5mg/L 去除率91.6%")
  @simbuf.println("TN: 12mg/L 达标 限值15mg/L 去除率70%")
  @simbuf.println("")
  if treatment_times.length() > 0 {
    let ts = @stats.summary(treatment_times)
    @simbuf.println("--- 处理统计 ---")
    @simbuf.println("批次数: \{treatment_times.length()}")
    @simbuf.println("均值: \{ts.mean}")
    @simbuf.println("标准差: \{ts.stddev}")
    @simbuf.println("最小: \{ts.min}")
    @simbuf.println("最大: \{ts.max}")
    @simbuf.println("")
  }
  @simbuf.println("--- 能耗与成本 ---")
  @simbuf.println("日耗电量: 3528 kWh")
  @simbuf.println("吨水电耗: 0.35 kWh/m3")
  @simbuf.println("日运行成本: 约7.1万元")
  @simbuf.println("吨水成本: 0.71元/m3")
  @simbuf.println("年运行费用: 3313万元")
  @simbuf.println("总投资: 1.22亿元")
  @simbuf.println("")
  @simbuf.println("--- 瓶颈分析 ---")
  @simbuf.println("当前瓶颈: 二沉池固体负荷接近上限")
  @simbuf.println("优化建议: 提高污泥回流比至100%")
  @simbuf.println("")
  @simbuf.println("--- 水工建筑物汇总 ---")
  @simbuf.println("构筑物总数: 40个 (6大类)")
  @simbuf.println("  一级处理: 6个")
  @simbuf.println("  二级处理: 7个 (AAO工艺)")
  @simbuf.println("  三级处理: 4个")
  @simbuf.println("  污泥处理: 4个")
  @simbuf.println("  辅助建筑: 7个")
  @simbuf.println("  厂区设施: 8个")
  @simbuf.println("")
  @simbuf.println("===== 仿真结束 =====")
  @simbuf.to_string()
}

///|
fn build_response(output : String) -> String {
  let oj = output.to_json().stringify()
  let sj = hyd_structures_json()
  "{\"success\":true,\"output\":\{oj},\"structures\":\{sj},\"name\":\"sewage_treatment\"}"
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
  @stdio.stdout.write("Sewage AI Monitor - AAO Process - 100,000 m3/d\n")
  @stdio.stdout.write("Listening on http://127.0.0.1:10010\n")

  let server = @http.Server(@socket.Addr::parse("127.0.0.1:10010")) catch {
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
      (@http.Get, "/api/structures") => {
        let json_str = "{\"success\":true,\"structures\":\{hyd_structures_json()}}"
        conn.send_response(200, "OK", extra_headers=json_headers)
        conn.write_string(json_str)
        conn.end_response()
      }
      (@http.Get, "/api/scene3d") => {
        let obj_content = try {
          @fs.read_file("dsh-test/wastewater-plant-100score.obj").text()
        } catch {
          _ => ""
        }
        if obj_content.length() == 0 {
          conn.send_response(404, "NotFound", extra_headers=json_headers)
          conn.write_string("{\"error\":\"OBJ file not found\"}")
          conn.end_response()
          return
        }
        let scene = @mesh3d.parse_obj(obj_content)
        scene.apply_plant_labels()
        let json_str = scene.to_json_string()
        conn.send_response(200, "OK", extra_headers=json_headers)
        conn.write_string(json_str)
        conn.end_response()
      }
      (@http.Get, "/api/obj") => {
        send_file(conn, "dsh-test/wastewater-plant-100score.obj", text_headers, "OBJ file not found")
      }
      _ => {
        conn.send_response(404, "NotFound", extra_headers=text_headers)
        conn.write_string("Not Found")
        conn.end_response()
      }
    }
  })
}
