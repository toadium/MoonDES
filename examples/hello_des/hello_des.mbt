///|
/// 示例 1：Hello DES —— 最简事件调度
///
/// 演示如何创建仿真环境、调度事件、运行主循环。
/// 三个事件按时间顺序触发，输出各自的发生时间。
fn main {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  ignore(
    env.schedule(time=3.0, callback=fn() {
      log.push("事件 A 在 \{env.now()} 触发")
    }),
  )
  ignore(
    env.schedule(time=1.0, callback=fn() {
      log.push("事件 B 在 \{env.now()} 触发")
    }),
  )
  ignore(
    env.schedule(time=7.0, callback=fn() {
      log.push("事件 C 在 \{env.now()} 触发")
    }),
  )
  env.run()
  for line in log {
    println(line)
  }
  println("仿真结束时间: \{env.now()}")
}
