///|
/// 示例 2：M/M/1 排队系统
///
/// 单服务台排队模型：顾客按间隔到达，服务台逐一服务。
/// 使用 Process 层创建到达进程和服务进程，统计系统指标。
fn main {
  let env = @core.new_env(until=100.0)
  let mut served : Int = 0
  let mut queue_len : Int = 0
  let mut max_queue : Int = 0
  let server = @resource.new_exclusive(name="server")
  ignore(
    @process.process(env, name="arrival", behavior=fn(p) {
      queue_len = queue_len + 1
      if queue_len > max_queue {
        max_queue = queue_len
      }
      ignore(
        server.request(pid=p.id(), callback=fn() {
          queue_len = queue_len - 1
          served = served + 1
          server.release()
        }),
      )
      @process.Timeout(duration=10.0, next=fn() {
        queue_len = queue_len + 1
        if queue_len > max_queue {
          max_queue = queue_len
        }
        ignore(
          server.request(pid=p.id(), callback=fn() {
            queue_len = queue_len - 1
            served = served + 1
            server.release()
          }),
        )
        @process.Done
      })
    }),
  )
  env.run()
  println("=== M/M/1 排队系统仿真结果 ===")
  println("仿真时长: \{env.now()}")
  println("已服务顾客数: \{served}")
  println("最大排队长度: \{max_queue}")
}
