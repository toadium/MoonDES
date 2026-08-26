///|
/// MoonDES 全栈后端服务器
///
/// Native HTTP 服务器，提供：
/// - GET  /              → 静态 index.html
/// - GET  /frontend.js   → 前端 JS bundle
/// - GET  /api/examples  → 示例列表 JSON
/// - POST /api/simulate  → 运行仿真，返回结果 JSON（含 mermaid 图表 + 统计卡片）
///
/// 运行：moon run backend --target native

///|
/// 构建 headers Map
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

let js_headers : @http.Headers = make_headers([
  ("Content-Type", "application/javascript; charset=utf-8"),
])

let text_headers : @http.Headers = make_headers([
  ("Content-Type", "text/plain; charset=utf-8"),
])

///|
/// 根据示例名称运行仿真
fn run_simulation(name : String) -> @shared.SimulationResponse {
  let output = match name {
    "hello_des" => @hello_des.run()
    "mm1_queue" => @mm1_queue.run()
    "mmc_queue" => @mmc_queue.run()
    "producer_consumer" => @producer_consumer.run()
    "dining_philosophers" => @dining_philosophers.run()
    "resource_sharing" => @resource_sharing.run()
    "traffic_system" => @traffic_system.run()
    "elevator_dispatch" => @elevator_dispatch.run()
    "sensor_network" => @sensor_network.run()
    "network_simulation" => @network_simulation.run()
    "monte_carlo_pi" => @monte_carlo_pi.run()
    "benchmark" => @benchmark.run()
    "hospital_er" => @hospital_er.run()
    "factory_machine" => @factory_machine.run()
    "water_treatment" => @water_treatment.run()
    "sewage_treatment" => @sewage_treatment.run()
    "social_network" => @social_network.run()
    "epidemic_spread" => @epidemic_spread.run()
    "forest_fire" => @forest_fire.run()
    _ => ""
  }
  if output == "" {
    @shared.SimulationResponse::{
      name,
      output: "",
      duration_ms: 0,
      success: false,
      error: Some("Unknown example: \{name}"),
      mermaid: None,
      stats: [],
    }
  } else {
    @shared.SimulationResponse::{
      name,
      output,
      duration_ms: 0,
      success: true,
      error: None,
      mermaid: gen_mermaid(name),
      stats: gen_stats(name),
    }
  }
}

///|
/// 发送文件响应
async fn send_file(
  conn : @http.ServerConnection,
  path : String,
  headers : @http.Headers,
  error_msg : String,
) -> Unit {
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
/// 主入口
async fn main {
  @stdio.stdout.write("MoonDES Full-Stack Backend\n")
  @stdio.stdout.write("==========================\n")
  @stdio.stdout.write("Listening on http://127.0.0.1:8080\n")
  @stdio.stdout.write("\n19 simulations ready.\n")

  let server = @http.Server(@socket.Addr::parse("127.0.0.1:8080")) catch {
    err => {
      @stdio.stdout.write("Failed to start server: \{err}\n")
      return
    }
  }

  server.run_forever(fn(request, body, conn) {
    match (request.meth, request.path) {
      (@http.Options, _) => {
        conn.send_response(204, "NoContent", extra_headers=json_headers)
        conn.end_response()
      }
      (@http.Get, "/") =>
        send_file(conn, "backend/index.html", html_headers, "Missing backend/index.html")
      (@http.Get, "/frontend.js") =>
        send_file(conn, "backend/frontend.js", js_headers, "Missing frontend bundle")
      (@http.Get, "/api/examples") => {
        let list = @shared.example_list()
        let json_str = list.to_json().stringify()
        conn.send_response(200, "OK", extra_headers=json_headers)
        conn.write_string(json_str)
        conn.end_response()
      }
      (@http.Post, "/api/simulate") => {
        let raw_body = try {
          body.read_all().text()
        } catch {
          _ => ""
        }
        let response : @shared.SimulationResponse = try {
          let req : @shared.SimulationRequest = @json.from_json(@json.parse(raw_body))
          run_simulation(req.name)
        } catch {
          err => {
            @shared.SimulationResponse::{
              name: "",
              output: "",
              duration_ms: 0,
              success: false,
              error: Some("Invalid request: \{err}"),
              mermaid: None,
              stats: [],
            }
          }
        }
        let json_str = response.to_json().stringify()
        let code = if response.success { 200 } else { 400 }
        let reason = if response.success { "OK" } else { "BadRequest" }
        conn.send_response(code, reason, extra_headers=json_headers)
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
