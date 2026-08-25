// ===========================================================================
// Pipeline — 流水线测试
// ===========================================================================

///|
/// Pipeline：基本添加
test "pipeline basic add" {
  let p = new_pipeline()
  p.add_stage(name="intake", capacity=10, processing_time=2.0)
  assert_eq(p.stage_count(), 1)
  assert_false(p.is_empty())
  let s = p.get(0)
  assert_eq(s.name, "intake")
  assert_eq(s.capacity, 10)
  assert_eq(s.processing_time, 2.0)
}

///|
/// Pipeline：多阶段
test "pipeline multi stage" {
  let p = new_pipeline()
  p.add_stage(name="a", capacity=5, processing_time=1.0)
  p.add_stage(name="b", capacity=3, processing_time=2.0)
  p.add_stage(name="c", capacity=8, processing_time=3.0)
  assert_eq(p.stage_count(), 3)
  let names = p.stage_names()
  assert_eq(names[0], "a")
  assert_eq(names[1], "b")
  assert_eq(names[2], "c")
}

///|
/// Pipeline：总处理时间
test "pipeline total processing time" {
  let p = new_pipeline()
  p.add_stage(name="a", capacity=5, processing_time=1.5)
  p.add_stage(name="b", capacity=3, processing_time=2.5)
  p.add_stage(name="c", capacity=8, processing_time=3.0)
  assert_eq(p.total_processing_time(), 7.0)
}

///|
/// Pipeline：总容量
test "pipeline total capacity" {
  let p = new_pipeline()
  p.add_stage(name="a", capacity=5, processing_time=1.0)
  p.add_stage(name="b", capacity=3, processing_time=2.0)
  assert_eq(p.total_capacity(), 8)
}

///|
/// Pipeline：空流水线
test "pipeline empty" {
  let p = new_pipeline()
  assert_true(p.is_empty())
  assert_eq(p.stage_count(), 0)
  assert_eq(p.total_processing_time(), 0.0)
  assert_eq(p.total_capacity(), 0)
}

///|
/// Pipeline：to_string
test "pipeline to_string" {
  let p = new_pipeline()
  p.add_stage(name="intake", capacity=10, processing_time=2.0)
  p.add_stage(name="filter", capacity=5, processing_time=5.0)
  let s = p.to_string()
  assert_true(s.contains("Pipeline"))
  assert_true(s.contains("intake"))
  assert_true(s.contains("filter"))
  assert_true(s.contains("7"))
}

///|
/// Pipeline：瓶颈阶段
test "pipeline bottleneck" {
  let p = new_pipeline()
  p.add_stage(name="a", capacity=10, processing_time=1.0)
  p.add_stage(name="b", capacity=3, processing_time=2.0)
  p.add_stage(name="c", capacity=8, processing_time=3.0)
  match p.bottleneck() {
    Some(idx) => assert_eq(idx, 1) // b has capacity 3
    None => assert_true(false)
  }
}

///|
/// Pipeline：空流水线瓶颈
test "pipeline empty bottleneck" {
  let p = new_pipeline()
  match p.bottleneck() {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
/// Pipeline：stages 列表
test "pipeline stages list" {
  let p = new_pipeline()
  p.add_stage(name="x", capacity=1, processing_time=1.0)
  p.add_stage(name="y", capacity=2, processing_time=2.0)
  let stages = p.stages()
  assert_eq(stages.length(), 2)
  assert_eq(stages[0].name, "x")
  assert_eq(stages[1].name, "y")
}
