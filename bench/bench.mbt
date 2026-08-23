///|
/// 基准测试套件入口
///
/// 确保所有导入被引用。基准测试在 `bench_test.mbt` 中定义。
pub fn bench_info() -> String {
  let _env = @core.new_env(until=1.0)
  let _sem = @sync.new_semaphore(count=1)
  let _res = @resource.new_exclusive(name="bench")
  let _p = @process.process(_env, behavior=fn(_) { @process.Done })
  "MoonDES Benchmark Suite v1.9.0"
}
