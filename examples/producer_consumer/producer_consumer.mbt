///|
/// 示例：生产者-消费者模型
///
/// 生产者将产品放入 Store，消费者从 Store 取出产品。
/// Store 空时消费者阻塞等待。使用 Store[T] 实现异步解耦。
///
/// 运行：moon run ./examples/producer_consumer --target wasm
fn main {
  let env = @core.new_env(until=30.0)
  let store : @sync.Store[Int] = @sync.new_store()
  let mut produced = 0
  let mut consumed = 0

  // 生产者：每 2 个时间单位生产一个产品
  ignore(
    @process.process(env, name="producer", behavior=fn(_) {
      @process.Timeout(duration=2.0, next=fn() {
        produced = produced + 1
        store.put(produced)
        @process.Timeout(duration=2.0, next=fn() {
          produced = produced + 1
          store.put(produced)
          @process.Timeout(duration=2.0, next=fn() {
            produced = produced + 1
            store.put(produced)
            @process.Timeout(duration=2.0, next=fn() {
              produced = produced + 1
              store.put(produced)
              @process.Timeout(duration=2.0, next=fn() {
                produced = produced + 1
                store.put(produced)
                @process.Done
              })
            })
          })
        })
      })
    }),
  )

  // 消费者：从 Store 取产品，消费后等 3 单位再取下一个
  ignore(
    @process.process(env, name="consumer", behavior=fn(_) {
      store.get(fn(_item) {
        consumed = consumed + 1
        ignore(
          env.schedule(time=env.now() + 3.0, callback=fn() {
            store.get(fn(_item2) {
              consumed = consumed + 1
              ignore(
                env.schedule(time=env.now() + 3.0, callback=fn() {
                  store.get(fn(_item3) {
                    consumed = consumed + 1
                    ignore(
                      env.schedule(time=env.now() + 3.0, callback=fn() {
                        store.get(fn(_item4) { consumed = consumed + 1 })
                      }),
                    )
                  })
                }),
              )
            })
          }),
        )
      })
      @process.Done
    }),
  )

  env.run()
  println("Producer-Consumer (Store[Int])")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("Produced: \{produced}")
  println("Consumed: \{consumed}")
  println("Remaining in store: \{store.size()}")
}
