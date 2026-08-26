///|
/// MoonDES 全栈前端 — Rabbita UI
///
/// 19 个仿真示例的交互式 Web UI：
/// - 左侧示例列表（分类标注）
/// - 右侧仿真描述 + 运行按钮 + 输出展示
///
/// 构建：moon build frontend --target js

///|
/// UI 状态
struct Model {
  examples : Array[@shared.ExampleInfo]
  selected : Int
  output : String
  running : Bool
  error : String?
}

///|
/// UI 消息
enum Msg {
  Select(Int)
  Run
  SimResult(String)
  SimError(String)
}

///|
/// 初始状态——示例列表来自 shared 包，无需 HTTP 请求
fn init_model() -> Model {
  {
    examples: @shared.all_examples,
    selected: 0,
    output: "",
    running: false,
    error: None,
  }
}

///|
/// 解析仿真响应 JSON
fn parse_response(raw : String) -> Msg {
  try {
    let resp : @shared.SimulationResponse = @json.from_json(@json.parse(raw))
    if resp.success {
      SimResult(resp.output)
    } else {
      let err = match resp.error {
        Some(e) => e
        None => "Unknown error"
      }
      SimError(err)
    }
  } catch {
    e => SimError("JSON parse error: \{e}")
  }
}

///|
/// 更新函数
fn update(dispatch : @rabbita.Emit[Msg], msg : Msg, model : Model) -> (@rabbita.Cmd, Model) {
  match msg {
    Select(idx) => {
      (@rabbita.none, { ..model, selected: idx, output: "", error: None })
    }
    Run => {
      if model.running || model.examples.length() == 0 {
        (@rabbita.none, model)
      } else {
        let ex = model.examples[model.selected]
        let request = @shared.SimulationRequest::{ name: ex.name, params: "{}" }
        let request_json = request.to_json().stringify()
        let cmd = @rhttp.post("/api/simulate")
          .with_text(request_json)
          .expect_text(fn(result) {
            match result {
              Ok(raw) => dispatch(parse_response(raw))
              Err(_) => dispatch(SimError("HTTP request failed"))
            }
          })
        (cmd, { ..model, running: true, output: "", error: None })
      }
    }
    SimResult(output) => {
      (@rabbita.none, { ..model, running: false, output, error: None })
    }
    SimError(err) => {
      (@rabbita.none, { ..model, running: false, error: Some(err) })
    }
  }
}

///|
/// 视图函数
fn view(dispatch : @rabbita.Emit[Msg], model : Model) -> @html.Html {
  // 侧边栏：示例列表
  let sidebar_items : Array[@html.Html] = []
  for i in 0..<model.examples.length() {
    let ex = model.examples[i]
    let cls = if i == model.selected { "example-item active" } else { "example-item" }
    sidebar_items.push(
      @html.div(
        class=cls,
        on_click=dispatch(Select(i)),
        [
          @html.div(class="title", [@html.text(ex.title)]),
          @html.div(class="cat", [@html.text(ex.category)]),
        ],
      ),
    )
  }

  let sidebar = @html.div(
    class="sidebar",
    [
      @html.h2([@html.text("仿真示例")]),
      @html.div(class="example-list", sidebar_items),
    ],
  )

  // 主区域
  let (title_text, desc_text) = if model.examples.length() > 0 {
    let ex = model.examples[model.selected]
    (ex.title, ex.description)
  } else {
    ("加载中...", "")
  }

  let run_label = if model.running { "运行中..." } else { "运行仿真" }
  let run_btn = @html.button(
    class="btn-run",
    on_click=dispatch(Run),
    [@html.text(run_label)],
  )

  // 输出区域
  let output_html = if model.running {
    @html.pre(class="output", [@html.text("正在运行仿真...")])
  } else if model.output != "" {
    @html.pre(class="output", [@html.text(model.output)])
  } else {
    match model.error {
      Some(e) =>
        @html.pre(class="output", [@html.text("错误: \{e}")])
      None =>
        @html.div(
          class="output",
          [
            @html.div(
              class="placeholder",
              [@html.text("点击左侧示例，然后运行仿真")],
            ),
          ],
        )
    }
  }

  let main_area = @html.div(
    class="main",
    [
      @html.h2([@html.text(title_text)]),
      @html.p(class="desc", [@html.text(desc_text)]),
      run_btn,
      output_html,
    ],
  )

  @html.div(class="container", [sidebar, main_area])
}

///|
/// 主入口
fn main {
  let app = @rabbita.cell(
    model=init_model(),
    update~,
    view~,
  )
  @rabbita.new(app).mount("app")
}
