///|
/// MoonDES 全栈共享合约
///
/// 定义前端与后端之间的类型安全通信合约。
/// 前端（Rabbita UI）发送 SimulationRequest，后端返回 SimulationResponse。

// ===========================================================================
// 仿真请求/响应类型
// ===========================================================================

///|
/// 仿真请求
pub(all) struct SimulationRequest {
  name : String       // 示例名称
  params : String     // JSON 参数（预留扩展）
} derive(Eq, ToJson, FromJson)

///|
/// 仿真响应
pub(all) struct SimulationResponse {
  name : String       // 示例名称
  output : String     // 仿真输出文本
  duration_ms : Int   // 运行耗时（毫秒）
  success : Bool      // 是否成功
  error : String?     // 错误信息
} derive(Eq, ToJson, FromJson)

///|
/// 示例列表项
pub(all) struct ExampleInfo {
  name : String       // 包名（用于 API 调用）
  title : String      // 显示标题
  category : String   // 分类
  description : String // 简短描述
} derive(Eq, ToJson, FromJson)

///|
/// 示例列表响应
pub(all) struct ExampleListResponse {
  examples : Array[ExampleInfo]
  total : Int
} derive(Eq, ToJson, FromJson)

// ===========================================================================
// 全部 19 个示例的元数据
// ===========================================================================

///|
/// 所有示例列表
pub let all_examples : Array[ExampleInfo] = [
  { name: "hello_des", title: "Hello DES", category: "基础", description: "最简事件调度——三个事件按时间顺序触发" },
  { name: "mm1_queue", title: "M/M/1 排队", category: "排队论", description: "单服务台排队系统仿真" },
  { name: "mmc_queue", title: "M/M/c 排队", category: "排队论", description: "多服务台排队系统仿真" },
  { name: "producer_consumer", title: "生产者-消费者", category: "并发", description: "生产者与消费者通过缓冲区协作" },
  { name: "dining_philosophers", title: "哲学家就餐", category: "并发", description: "五个哲学家共享叉子的经典并发问题" },
  { name: "resource_sharing", title: "资源共享", category: "并发", description: "多进程竞争共享资源" },
  { name: "traffic_system", title: "交通系统", category: "网络", description: "十字路口交通灯调度与车辆通行" },
  { name: "elevator_dispatch", title: "电梯调度", category: "网络", description: "多电梯调度系统，FSM 驱动" },
  { name: "sensor_network", title: "传感器网络", category: "网络", description: "无线传感器网络监测与数据汇聚" },
  { name: "network_simulation", title: "网络仿真", category: "网络", description: "网络节点通信与数据包传输" },
  { name: "monte_carlo_pi", title: "蒙特卡洛 π", category: "概率", description: "蒙特卡洛方法估算圆周率" },
  { name: "benchmark", title: "性能基准", category: "概率", description: "事件调度/进程调度/M/M/1 性能测试" },
  { name: "hospital_er", title: "医院急诊", category: "综合", description: "急诊室资源调度+条件变量+FSM" },
  { name: "factory_machine", title: "工厂机器", category: "综合", description: "工厂机器运转与故障维修仿真" },
  { name: "water_treatment", title: "自来水处理", category: "工业", description: "多阶段水处理工艺流水线" },
  { name: "sewage_treatment", title: "污水处理", category: "工业", description: "污水处理厂工艺流程仿真" },
  { name: "social_network", title: "社交网络", category: "图网络", description: "人脉关系网——图算法+事件总线" },
  { name: "epidemic_spread", title: "传染病传播", category: "图网络", description: "SIR 传染病模型——Markov+Graph+FSM" },
  { name: "forest_fire", title: "森林火灾", category: "空间", description: "森林火灾扩散——Grid2D+CA+FSM" },
]

///|
/// 获取示例列表响应
pub fn example_list() -> ExampleListResponse {
  { examples: all_examples, total: all_examples.length() }
}

///|
/// 根据名称查找示例
pub fn find_example(name : String) -> ExampleInfo? {
  for ex in all_examples {
    if ex.name == name {
      return Some(ex)
    }
  }
  None
}
