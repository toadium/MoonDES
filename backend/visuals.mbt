///|
/// MoonDES 仿真可视化生成器
///
/// 为每个仿真示例生成 Mermaid 图表 + 统计卡片

///|
/// 生成 Mermaid 图表源码
pub fn gen_mermaid(name : String) -> String? {
  match name {
    "hello_des" => Some("timeline\n    title 事件调度时间线\n    section DES 仿真\n        t=1 : 事件 B 触发\n        t=3 : 事件 A 触发\n        t=7 : 事件 C 触发\n        t=20: 仿真结束")
    "mm1_queue" => Some("flowchart LR\n    A[顾客到达<br/>λ=0.1] --> Q[(排队队列)]\n    Q --> S[服务台<br/>μ=0.2]\n    S --> D[服务完成]\n    style A fill:#4caf50,color:#fff\n    style Q fill:#ff9800,color:#fff\n    style S fill:#2196f3,color:#fff\n    style D fill:#9c27b0,color:#fff")
    "mmc_queue" => Some("flowchart LR\n    A[顾客到达] --> Q[(排队队列)]\n    Q --> S1[服务台 1]\n    Q --> S2[服务台 2]\n    Q --> S3[服务台 3]\n    S1 --> D[服务完成]\n    S2 --> D\n    S3 --> D\n    style A fill:#4caf50,color:#fff\n    style Q fill:#ff9800,color:#fff\n    style D fill:#9c27b0,color:#fff")
    "producer_consumer" => Some("flowchart LR\n    P1[生产者 1] --> B[(缓冲区<br/>容量=5)]\n    P2[生产者 2] --> B\n    B --> C1[消费者 1]\n    B --> C2[消费者 2]\n    style P1 fill:#4caf50,color:#fff\n    style P2 fill:#4caf50,color:#fff\n    style B fill:#ff9800,color:#fff\n    style C1 fill:#2196f3,color:#fff\n    style C2 fill:#2196f3,color:#fff")
    "dining_philosophers" => Some("stateDiagram-v2\n    [*] --> 思考\n    思考 --> 饥饿 : 拿左叉\n    饥饿 --> 就餐 : 拿右叉\n    就餐 --> 思考 : 放下双叉\n    饥饿 --> 思考 : 超时放弃\n    note right of 就餐 : 资源层次策略<br/>避免死锁")
    "resource_sharing" => Some("flowchart TD\n    P1[进程 1] --> R1{资源 A<br/>互斥}\n    P2[进程 2] --> R1\n    P3[进程 3] --> R2{资源 B<br/>互斥}\n    P4[进程 4] --> R2\n    P1 --> R2\n    P3 --> R1\n    style R1 fill:#ff9800,color:#fff\n    style R2 fill:#ff9800,color:#fff")
    "traffic_system" => Some("stateDiagram-v2\n    [*] --> 南北绿\n    南北绿 --> 南北黄 : 定时器\n    南北黄 --> 东西绿 : 换向\n    东西绿 --> 东西黄 : 定时器\n    东西黄 --> 南北绿 : 换向\n    note right of 南北绿 : 南北通行<br/>东西红灯\n    note right of 东西绿 : 东西通行<br/>南北红灯")
    "elevator_dispatch" => Some("stateDiagram-v2\n    [*] --> 空闲\n    空闲 --> 上行 : 收到上行呼叫\n    空闲 --> 下行 : 收到下行呼叫\n    上行 --> 停止 : 到达目标层\n    下行 --> 停止 : 到达目标层\n    停止 --> 空闲 : 开门→关门\n    上行 --> 上行 : 经过中间层\n    下行 --> 下行 : 经过中间层")
    "sensor_network" => Some("flowchart TD\n    S1[传感器 1] --> H[汇聚节点]\n    S2[传感器 2] --> H\n    S3[传感器 3] --> H\n    S4[传感器 4] --> H\n    S5[传感器 5] --> H\n    S6[传感器 6] --> H\n    S7[传感器 7] --> H\n    S8[传感器 8] --> H\n    H --> DB[(数据中心)]\n    style H fill:#e91e63,color:#fff\n    style DB fill:#9c27b0,color:#fff")
    "network_simulation" => Some("flowchart TD\n    N1[节点 A] <--> N2[节点 B]\n    N2 <--> N3[节点 C]\n    N3 <--> N4[节点 D]\n    N1 <--> N5[节点 E]\n    N5 <--> N6[节点 F]\n    N4 <--> N6\n    style N1 fill:#2196f3,color:#fff\n    style N6 fill:#2196f3,color:#fff")
    "monte_carlo_pi" => Some("flowchart TD\n    A[开始] --> B[随机生成点 x,y ∈ 0,1]\n    B --> C{x² + y² ≤ 1?}\n    C -->|是| D[圆内计数+1]\n    C -->|否| E[圆外计数+1]\n    D --> F{达到采样数?}\n    E --> F\n    F -->|否| B\n    F -->|是| G[π ≈ 4 × 圆内/总数]\n    G --> H[结束]\n    style A fill:#4caf50,color:#fff\n    style G fill:#ff9800,color:#fff\n    style H fill:#9c27b0,color:#fff")
    "benchmark" => Some("flowchart LR\n    A[性能基准测试] --> B[事件调度器]\n    A --> C[进程调度器]\n    A --> D[M/M/1 排队]\n    B --> E[统计耗时]\n    C --> E\n    D --> E\n    E --> F[对比报告]\n    style A fill:#2196f3,color:#fff\n    style F fill:#ff9800,color:#fff")
    "hospital_er" => Some("flowchart TD\n    P[病人到达] --> T[分诊台]\n    T -->|轻症| W1[普通候诊]\n    T -->|重症| W2[紧急候诊]\n    W1 --> DR[医生诊治]\n    W2 --> DR\n    DR --> Bed[病床观察]\n    Bed --> Out[出院]\n    style T fill:#ff9800,color:#fff\n    style W2 fill:#f44336,color:#fff\n    style Out fill:#4caf50,color:#fff")
    "factory_machine" => Some("stateDiagram-v2\n    [*] --> 运行\n    运行 --> 故障 : 随机故障\n    故障 --> 维修中 : 维修工到达\n    维修中 --> 运行 : 维修完成\n    运行 --> 运行 : 加工产品\n    note right of 故障 : 触发维修请求\n    note right of 维修中 : 资源互斥")
    "water_treatment" => Some("flowchart LR\n    S1[取水<br/>cap=20] --> S2[混凝<br/>cap=15]\n    S2 --> S3[沉淀<br/>cap=10]\n    S3 --> S4[过滤<br/>cap=8]\n    S4 --> S5[消毒<br/>cap=12]\n    S5 --> S6[供水<br/>cap=30]\n    style S4 fill:#f44336,color:#fff\n    style S6 fill:#4caf50,color:#fff")
    "sewage_treatment" => Some("flowchart LR\n    S1[格栅<br/>拦截杂物] --> S2[沉砂<br/>去除砂粒]\n    S2 --> S3[初沉<br/>悬浮物沉降]\n    S3 --> S4[生化<br/>活性污泥]\n    S4 --> S5[二沉<br/>泥水分离]\n    S5 --> S6[消毒<br/>紫外线]\n    S6 --> S7[排放<br/>达标出水]\n    style S4 fill:#ff9800,color:#fff\n    style S7 fill:#4caf50,color:#fff")
    "social_network" => Some("flowchart TD\n    A[用户 A] -->|关注| B[用户 B]\n    B -->|关注| C[用户 C]\n    C -->|关注| A\n    A -->|关注| D[用户 D]\n    D -->|关注| E[用户 E]\n    E -->|关注| B\n    C -->|关注| E\n    style A fill:#2196f3,color:#fff\n    style B fill:#2196f3,color:#fff")
    "epidemic_spread" => Some("stateDiagram-v2\n    [*] --> S\n    S --> E : 接触感染 30%\n    E --> I : 潜伏转阳 70%\n    I --> R : 康复 40%\n    note right of S : 易感者 Susceptible\n    note right of E : 潜伏者 Exposed\n    note right of I : 感染者 Infected\n    note right of R : 康复者 Recovered")
    "forest_fire" => Some("stateDiagram-v2\n    [*] --> Normal\n    Normal --> Watch : 燃烧≥3\n    Watch --> Warning : 燃烧≥10\n    Warning --> Critical : 燃烧≥20\n    Critical --> Contained : 扑灭\n    Warning --> Contained : 扑灭\n    Watch --> Contained : 扑灭\n    note right of Critical : 火势严重<br/>紧急响应")
    _ => None
  }
}

///|
/// 生成统计卡片
pub fn gen_stats(name : String) -> Array[@shared.StatCard] {
  match name {
    "hello_des" => [
      { label: "事件数", value: "3", unit: "个", color: "blue" },
      { label: "仿真时长", value: "20", unit: "tu", color: "cyan" },
      { label: "调度器", value: "DES", unit: "", color: "purple" },
    ]
    "mm1_queue" => [
      { label: "服务台", value: "1", unit: "个", color: "blue" },
      { label: "到达率", value: "0.1", unit: "λ", color: "cyan" },
      { label: "仿真时长", value: "100", unit: "tu", color: "purple" },
    ]
    "mmc_queue" => [
      { label: "服务台", value: "3", unit: "个", color: "blue" },
      { label: "模型", value: "M/M/c", unit: "", color: "green" },
      { label: "仿真时长", value: "200", unit: "tu", color: "purple" },
    ]
    "producer_consumer" => [
      { label: "生产者", value: "2", unit: "个", color: "blue" },
      { label: "消费者", value: "2", unit: "个", color: "green" },
      { label: "缓冲区", value: "5", unit: "槽", color: "orange" },
    ]
    "dining_philosophers" => [
      { label: "哲学家", value: "5", unit: "位", color: "blue" },
      { label: "叉子", value: "5", unit: "把", color: "orange" },
      { label: "策略", value: "层次", unit: "", color: "green" },
    ]
    "resource_sharing" => [
      { label: "进程数", value: "4", unit: "个", color: "blue" },
      { label: "资源", value: "2", unit: "个", color: "orange" },
      { label: "同步", value: "互斥", unit: "", color: "green" },
    ]
    "traffic_system" => [
      { label: "路口", value: "1", unit: "个", color: "blue" },
      { label: "方向", value: "4", unit: "向", color: "cyan" },
      { label: "灯控", value: "FSM", unit: "", color: "purple" },
    ]
    "elevator_dispatch" => [
      { label: "电梯", value: "3", unit: "部", color: "blue" },
      { label: "楼层", value: "10", unit: "层", color: "cyan" },
      { label: "调度", value: "FSM", unit: "", color: "purple" },
    ]
    "sensor_network" => [
      { label: "传感器", value: "8", unit: "个", color: "blue" },
      { label: "汇聚", value: "1", unit: "个", color: "green" },
      { label: "拓扑", value: "星型", unit: "", color: "orange" },
    ]
    "network_simulation" => [
      { label: "节点", value: "6", unit: "个", color: "blue" },
      { label: "链路", value: "多跳", unit: "", color: "cyan" },
      { label: "协议", value: "转发", unit: "", color: "purple" },
    ]
    "monte_carlo_pi" => [
      { label: "采样", value: "10万", unit: "点", color: "blue" },
      { label: "方法", value: "MC", unit: "", color: "green" },
      { label: "目标", value: "π", unit: "", color: "orange" },
    ]
    "benchmark" => [
      { label: "测试项", value: "3", unit: "项", color: "blue" },
      { label: "调度器", value: "E+P", unit: "", color: "cyan" },
      { label: "对比", value: "基准", unit: "", color: "purple" },
    ]
    "hospital_er" => [
      { label: "医生", value: "3", unit: "位", color: "blue" },
      { label: "护士", value: "2", unit: "位", color: "green" },
      { label: "病床", value: "5", unit: "张", color: "orange" },
      { label: "CV", value: "✓", unit: "", color: "purple" },
    ]
    "factory_machine" => [
      { label: "机器", value: "5", unit: "台", color: "blue" },
      { label: "维修工", value: "2", unit: "人", color: "green" },
      { label: "状态", value: "FSM", unit: "", color: "purple" },
    ]
    "water_treatment" => [
      { label: "工艺", value: "6", unit: "步", color: "blue" },
      { label: "瓶颈", value: "过滤", unit: "", color: "red" },
      { label: "监测", value: "Timer", unit: "", color: "green" },
    ]
    "sewage_treatment" => [
      { label: "工艺", value: "7", unit: "步", color: "blue" },
      { label: "类型", value: "污水", unit: "", color: "orange" },
      { label: "监控", value: "Bus", unit: "", color: "green" },
    ]
    "social_network" => [
      { label: "用户", value: "10", unit: "人", color: "blue" },
      { label: "关系", value: "Graph", unit: "", color: "purple" },
      { label: "传播", value: "Bus", unit: "", color: "green" },
    ]
    "epidemic_spread" => [
      { label: "人群", value: "100", unit: "人", color: "blue" },
      { label: "模型", value: "SIR", unit: "", color: "red" },
      { label: "Markov", value: "✓", unit: "", color: "purple" },
    ]
    "forest_fire" => [
      { label: "网格", value: "20×20", unit: "", color: "blue" },
      { label: "CA", value: "Moore", unit: "", color: "orange" },
      { label: "FSM", value: "5态", unit: "", color: "red" },
    ]
    _ => []
  }
}
