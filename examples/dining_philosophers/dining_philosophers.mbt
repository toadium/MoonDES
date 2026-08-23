///|
/// 示例：哲学家就餐问题
///
/// N 位哲学家围桌，左右各一支叉子（Semaphore）。
/// 哲学家交替思考和就餐。使用 Semaphore 防止相邻哲学家同时拿同一支叉子。
///
/// 运行：moon run ./examples/dining_philosophers --target wasm
fn main {
  let n = 5
  let env = @core.new_env(until=50.0)
  let mut meals_served = 0

  // 创建 N 把叉子
  let forks : Array[@sync.Semaphore] = []
  for _ in 0..<n {
    forks.push(@sync.new_semaphore(count=1))
  }

  // 创建 N 位哲学家
  for i in 0..<n {
    let left = forks[i]
    let right = forks[(i + 1) % n]
    let name = "Philosopher-\{i}"
    ignore(
      @process.process(env, name~, behavior=fn(_) {
        @process.Timeout(duration=2.0, next=fn() {
          // 思考 → 拿叉 → 就餐 → 放叉 → 重复
          left.acquire(fn() {
            right.acquire(fn() {
              // 就餐
              ignore(
                env.schedule(time=env.now() + 3.0, callback=fn() {
                  meals_served = meals_served + 1
                  right.release()
                  left.release()
                  // 第二轮
                  ignore(
                    env.schedule(time=env.now() + 2.0, callback=fn() {
                      left.acquire(fn() {
                        right.acquire(fn() {
                          ignore(
                            env.schedule(time=env.now() + 3.0, callback=fn() {
                              meals_served = meals_served + 1
                              right.release()
                              left.release()
                            }),
                          )
                        })
                      })
                    }),
                  )
                }),
              )
            })
          })
          @process.Done
        })
      }),
    )
  }

  env.run()
  println("Dining Philosophers (N=\{n})")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("Meals served: \{meals_served}")
}
