///|
/// 流水线阶段
///
/// 描述一个处理阶段的名称、容量和处理时间。
pub(all) struct PipelineStage {
  name : String
  capacity : Int
  processing_time : Double
}

///|
/// 流水线
///
/// 多阶段处理流程的抽象。每个阶段有名称、容量和处理时间。
/// 适用于：水处理工艺、制造流水线、数据处理管道等场景。
///
/// # Example
/// ```mbt check
/// test {
///   let p = @pipeline.new_pipeline()
///   p.add_stage(name="intake", capacity=10, processing_time=2.0)
///   p.add_stage(name="filter", capacity=5, processing_time=5.0)
///   assert_eq(p.stage_count(), 2)
///   assert_eq(p.total_processing_time(), 7.0)
/// }
/// ```
pub(all) struct Pipeline {
  stages : Array[PipelineStage]
}

///|
/// 创建流水线
pub fn new_pipeline() -> Pipeline {
  { stages: [] }
}

///|
/// 添加阶段
pub fn Pipeline::add_stage(
  self : Pipeline,
  name~ : String,
  capacity~ : Int,
  processing_time~ : Double,
) -> Unit {
  self.stages.push({ name, capacity, processing_time })
}

///|
/// 阶段数
pub fn Pipeline::stage_count(self : Pipeline) -> Int {
  self.stages.length()
}

///|
/// 总处理时间
///
/// 所有阶段处理时间之和。
pub fn Pipeline::total_processing_time(self : Pipeline) -> Double {
  let mut total = 0.0
  for stage in self.stages {
    total += stage.processing_time
  }
  total
}

///|
/// 总容量
///
/// 所有阶段容量之和。
pub fn Pipeline::total_capacity(self : Pipeline) -> Int {
  let mut total = 0
  for stage in self.stages {
    total += stage.capacity
  }
  total
}

///|
/// 获取阶段
pub fn Pipeline::get(self : Pipeline, index : Int) -> PipelineStage {
  self.stages[index]
}

///|
/// 所有阶段
pub fn Pipeline::stages(self : Pipeline) -> Array[PipelineStage] {
  self.stages
}

///|
/// 阶段名称列表
pub fn Pipeline::stage_names(self : Pipeline) -> Array[String] {
  let names : Array[String] = []
  for stage in self.stages {
    names.push(stage.name)
  }
  names
}

///|
/// 人类可读描述
pub fn Pipeline::to_string(self : Pipeline) -> String {
  let mut s = "Pipeline (\{self.stages.length()} stages):\n"
  for i in 0..<self.stages.length() {
    let stage = self.stages[i]
    s += "  [\{i}] \{stage.name} — capacity=\{stage.capacity}, time=\{stage.processing_time}\n"
  }
  s += "  Total processing time: \{self.total_processing_time()}"
  s
}

///|
/// 是否为空
pub fn Pipeline::is_empty(self : Pipeline) -> Bool {
  self.stages.length() == 0
}

///|
/// 瓶颈阶段
///
/// 返回容量最小的阶段索引。若有多个则返回第一个。
pub fn Pipeline::bottleneck(self : Pipeline) -> Int? {
  if self.stages.length() == 0 {
    return None
  }
  let mut min_idx = 0
  let mut min_cap = self.stages[0].capacity
  for i in 1..<self.stages.length() {
    if self.stages[i].capacity < min_cap {
      min_cap = self.stages[i].capacity
      min_idx = i
    }
  }
  Some(min_idx)
}
