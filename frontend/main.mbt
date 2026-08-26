///|
/// MoonDES 全栈前端 — Rabbita UI
///
/// 19 个仿真示例的交互式 Web UI：
/// - 左侧示例列表（分类标注）
/// - 右侧仿真描述 + 运行按钮 + 统计卡片 + Mermaid 图表 + 文本输出
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
  mermaid : String?
  stats : Array[@shared.StatCard]
}

///|
/// UI 消息
enum Msg {
  Select(Int)
  Run
  SimResult(String, String?, Array[@shared.StatCard])
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
    mermaid: None,
    stats: [],
  }
}

///|
/// 解析仿真响应 JSON
fn parse_response(raw : String) -> Msg {
  try {
    let resp : @shared.SimulationResponse = @json.from_json(@json.parse(raw))
    if resp.success {
      SimResult(resp.output, resp.mermaid, resp.stats)
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
      (@rabbita.none, { ..model, selected: idx, output: "", error: None, mermaid: None, stats: [] })
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
        (cmd, { ..model, running: true, output: "", error: None, mermaid: None, stats: [] })
      }
    }
    SimResult(output, mermaid, stats) => {
      (@rabbita.none, { ..model, running: false, output, error: None, mermaid, stats })
    }
    SimError(err) => {
      (@rabbita.none, { ..model, running: false, error: Some(err) })
    }
  }
}

///|
/// 渲染统计卡片
fn view_stats(stats : Array[@shared.StatCard]) -> @html.Html {
  let cards : Array[@html.Html] = []
  for card in stats {
    let cls = "stat-card stat-\{card.color}"
    let value_text = if card.unit == "" {
      card.value
    } else {
      "\{card.value} \{card.unit}"
    }
    cards.push(
      @html.div(
        class=cls,
        [
          @html.div(class="stat-label", [@html.text(card.label)]),
          @html.div(class="stat-value", [@html.text(value_text)]),
        ],
      ),
    )
  }
  @html.div(class="stats-grid", cards)
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

  // 可视化区域：统计卡片 + Mermaid 图表
  let visual_html = if model.running {
    @html.div(class="visual-area", [
      @html.div(class="loading-spinner", [@html.text("正在运行仿真...")]),
    ])
  } else if model.output != "" {
    let parts : Array[@html.Html] = []
    // 统计卡片
    if model.stats.length() > 0 {
      parts.push(view_stats(model.stats))
    }
    // Mermaid 图表
    match model.mermaid {
      Some(m) =>
        parts.push(
          @html.div(class="mermaid-section", [
            @html.h3([@html.text("架构图表")]),
            @html.div(class="mermaid", [@html.text(m)]),
          ]),
        )
      None => ()
    }
    // 文本输出
    parts.push(
      @html.div(class="output-section", [
        @html.h3([@html.text("仿真输出")]),
        @html.pre(class="output", [@html.text(model.output)]),
      ]),
    )
    @html.div(class="visual-area", parts)
  } else {
    match model.error {
      Some(e) =>
        @html.div(class="visual-area", [
          @html.pre(class="output error-output", [@html.text("错误: \{e}")]),
        ])
      None =>
        @html.div(class="visual-area", [
          @html.div(
            class="output placeholder",
            [@html.text("点击左侧示例，然后运行仿真")],
          ),
        ])
    }
  }

  let main_area = @html.div(
    class="main",
    [
      @html.h2([@html.text(title_text)]),
      @html.p(class="desc", [@html.text(desc_text)]),
      run_btn,
      visual_html,
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
