///|
/// MoonDES 全栈前端 — Rabbita UI (v2 优化版)
///
/// 优化点：
/// - 侧边栏：按分类分组折叠，左色条选中反馈
/// - 运行按钮：三态（idle/running/completed）
/// - 输出区：工具栏（复制/下载/清空）
/// - 示例说明：折叠区（场景描述+知识点）

///|
/// 分类组定义
let category_groups : Array[(String, String)] = [
  ("基础", "📦"),
  ("排队论", "📊"),
  ("并发", "🔀"),
  ("网络", "🌐"),
  ("概率", "🎲"),
  ("综合", "🏥"),
  ("工业", "🏭"),
  ("图网络", "🕸️"),
  ("空间", "🔥"),
]

///|
/// UI 状态
struct Model {
  examples : Array[@shared.ExampleInfo]
  selected : Int
  output : String
  running : Bool
  completed : Bool
  error : String?
  mermaid : String?
  stats : Array[@shared.StatCard]
  collapsed : Array[Bool]  // 每个分类组的折叠状态
  show_info : Bool         // 示例说明折叠
}

///|
/// UI 消息
enum Msg {
  Select(Int)
  Run
  SimResult(String, String?, Array[@shared.StatCard])
  SimError(String)
  ToggleGroup(Int)
  ToggleInfo
  ClearOutput
}

///|
/// 初始状态
fn init_model() -> Model {
  let collapsed : Array[Bool] = []
  for _ in 0..<category_groups.length() {
    collapsed.push(false)
  }
  {
    examples: @shared.all_examples,
    selected: 0,
    output: "",
    running: false,
    completed: false,
    error: None,
    mermaid: None,
    stats: [],
    collapsed,
    show_info: false,
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
      (@rabbita.none, { ..model, selected: idx, output: "", error: None, mermaid: None, stats: [], completed: false, show_info: false })
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
        (cmd, { ..model, running: true, completed: false, output: "", error: None, mermaid: None, stats: [] })
      }
    }
    SimResult(output, mermaid, stats) => {
      (@rabbita.none, { ..model, running: false, completed: true, output, error: None, mermaid, stats })
    }
    SimError(err) => {
      (@rabbita.none, { ..model, running: false, completed: false, error: Some(err) })
    }
    ToggleGroup(idx) => {
      let new_collapsed : Array[Bool] = []
      for i in 0..<model.collapsed.length() {
        if i == idx {
          new_collapsed.push(not(model.collapsed[i]))
        } else {
          new_collapsed.push(model.collapsed[i])
        }
      }
      (@rabbita.none, { ..model, collapsed: new_collapsed })
    }
    ToggleInfo => {
      (@rabbita.none, { ..model, show_info: not(model.show_info) })
    }
    ClearOutput => {
      (@rabbita.none, { ..model, output: "", completed: false, mermaid: None, stats: [] })
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
/// 获取示例的分类组索引
fn group_index(cat : String) -> Int {
  for i in 0..<category_groups.length() {
    if category_groups[i].0 == cat {
      return i
    }
  }
  0
}

///|
/// 视图函数
fn view(dispatch : @rabbita.Emit[Msg], model : Model) -> @html.Html {
  // === 侧边栏：分组折叠 ===
  let sidebar_content : Array[@html.Html] = []
  // 为每个分类组生成折叠面板
  for gi in 0..<category_groups.length() {
    let (cat_name, cat_icon) = category_groups[gi]
    let is_collapsed = model.collapsed[gi]
    // 收集该组的示例
    let group_items : Array[@html.Html] = []
    for i in 0..<model.examples.length() {
      let ex = model.examples[i]
      if ex.category == cat_name {
        let cls = if i == model.selected { "example-item active" } else { "example-item" }
        group_items.push(
          @html.div(
            class=cls,
            on_click=dispatch(Select(i)),
            [@html.div(class="title", [@html.text(ex.title)])],
          ),
        )
      }
    }
    // 只渲染有示例的组
    if group_items.length() > 0 {
      let header_cls = if is_collapsed { "group-header collapsed" } else { "group-header" }
      sidebar_content.push(
        @html.div(
          class="group",
          [
            @html.div(
              class=header_cls,
              on_click=dispatch(ToggleGroup(gi)),
              [
                @html.span(class="group-icon", [@html.text(cat_icon)]),
                @html.span(class="group-name", [@html.text(cat_name)]),
                @html.span(class="group-count", [@html.text("\{group_items.length()}")]),
                @html.span(class="group-arrow", [@html.text(if is_collapsed { "▶" } else { "▼" })]),
              ],
            ),
          ],
        ),
      )
      if not(is_collapsed) {
        sidebar_content.push(
          @html.div(class="group-items", group_items),
        )
      }
    }
  }

  let sidebar = @html.div(
    class="sidebar",
    [
      @html.div(class="sidebar-header", [
        @html.h2([@html.text("仿真示例")]),
        @html.span(class="sidebar-count", [@html.text("\{model.examples.length()}")]),
      ]),
      @html.div(class="example-list", sidebar_content),
    ],
  )

  // === 主区域 ===
  let (title_text, desc_text) = if model.examples.length() > 0 {
    let ex = model.examples[model.selected]
    (ex.title, ex.description)
  } else {
    ("加载中...", "")
  }

  // 运行按钮三态
  let (run_label, run_cls) = if model.running {
    ("运行中...", "btn-run btn-running")
  } else if model.completed {
    ("重新运行", "btn-run btn-completed")
  } else {
    ("运行仿真", "btn-run btn-idle")
  }
  let run_btn = @html.button(
    class=run_cls,
    on_click=dispatch(Run),
    [@html.text(run_label)],
  )

  // 示例说明折叠区
  let info_section = if model.show_info {
    @html.div(class="info-section expanded", [
      @html.div(class="info-header", on_click=dispatch(ToggleInfo), [
        @html.span(class="info-icon", [@html.text("💡")]),
        @html.span([@html.text("示例说明")]),
        @html.div(class="info-toggle", on_click=dispatch(ToggleInfo), [@html.text("收起 ▲")]),
      ]),
      @html.div(class="info-body", [
        @html.p([@html.text(desc_text)]),
      ]),
    ])
  } else {
    @html.div(class="info-section", [
      @html.div(class="info-header", on_click=dispatch(ToggleInfo), [
        @html.span(class="info-icon", [@html.text("💡")]),
        @html.span([@html.text("示例说明")]),
        @html.div(class="info-toggle", on_click=dispatch(ToggleInfo), [@html.text("展开 ▼")]),
      ]),
    ])
  }

  // 可视化区域
  let visual_html = if model.running {
    @html.div(class="visual-area", [
      @html.div(class="loading-spinner", [
        @html.div(class="spinner", [@html.text("")]),
        @html.text("正在运行仿真..."),
      ]),
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
            @html.div(class="section-header", [
              @html.h3([@html.text("架构图表")]),
              @html.div(class="toolbar-buttons", [
                @html.button(class="tool-btn", id="btn-replay", [@html.text("重播动画")]),
              ]),
            ]),
            @html.div(class="mermaid", [@html.text(m)]),
          ]),
        )
      None => ()
    }
    // 输出区工具栏 + 文本
    parts.push(
      @html.div(class="output-section", [
        @html.div(class="section-header output-toolbar", [
          @html.h3([@html.text("仿真输出")]),
          @html.div(class="toolbar-buttons", [
            @html.button(class="tool-btn", on_click=dispatch(ClearOutput), [@html.text("清空")]),
            @html.button(class="tool-btn", id="btn-copy", [@html.text("复制")]),
            @html.button(class="tool-btn", id="btn-download", [@html.text("下载")]),
          ]),
        ]),
        @html.pre(class="output", id="sim-output", [@html.text(model.output)]),
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
      @html.div(class="main-header", [
        @html.h2([@html.text(title_text)]),
        @html.span(class="main-category", [@html.text(if model.examples.length() > 0 { model.examples[model.selected].category } else { "" })]),
      ]),
      info_section,
      @html.div(class="action-bar", [run_btn]),
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
