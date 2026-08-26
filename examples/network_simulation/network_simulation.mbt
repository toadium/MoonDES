///|
/// 示例：3 节点网络仿真
///
/// 拓扑：A --link_ab--> B --link_bc--> C
///
/// 节点 A 发送数据包到 C，经 B 路由转发。
/// B 维护路由表，将目的地 C 的包转发到 link_bc。
/// 统计吞吐量和延迟。
///
/// 运行：moon run ./examples/network_simulation --target wasm
pub fn run() -> String {
  @simbuf.clear()
  let env = @core.new_env(until=100.0)
  let mut received = 0
  let mut total_delay = 0.0

  // 创建链路
  let link_ab = @network.new_link(env, name="A→B", delay=5.0)
  let link_bc = @network.new_link(env, name="B→C", delay=3.0)

  // B 的路由表：目的地 C → link_bc
  let router_b = @network.new_router(name="B")
  router_b.add_route(dest="C", link_bc)

  // C 端接收
  link_bc.receive(fn(pkt) {
    received = received + 1
    total_delay = total_delay + env.now()
    @simbuf.println("[C] received '\{pkt.data}' from \{pkt.source} at t=\{env.now()}")
  })

  // B 端接收并路由转发
  link_ab.receive(fn(pkt) {
    @simbuf.println("[B] routing '\{pkt.data}' to \{pkt.dest} at t=\{env.now()}")
    ignore(router_b.send(pkt))
  })

  // A 端发送 3 个数据包
  ignore(
    @process.process(env, name="sender-A", behavior=fn(_) {
      @simbuf.println("[A] sending packet 1 at t=\{env.now()}")
      link_ab.send(
        @network.new_packet(source="A", dest="C", size=100, data="msg-1"),
      )
      @process.Timeout(duration=10.0, next=fn() {
        @simbuf.println("[A] sending packet 2 at t=\{env.now()}")
        link_ab.send(
          @network.new_packet(source="A", dest="C", size=200, data="msg-2"),
        )
        @process.Timeout(duration=15.0, next=fn() {
          @simbuf.println("[A] sending packet 3 at t=\{env.now()}")
          link_ab.send(
            @network.new_packet(source="A", dest="C", size=150, data="msg-3"),
          )
          @process.Done
        })
      })
    }),
  )

  env.run()
  @simbuf.println("")
  @simbuf.println("=== Network Simulation Results ===")
  @simbuf.println("Simulation time: \{env.now()}")
  @simbuf.println("Events processed: \{env.event_count()}")
  @simbuf.println("Packets received: \{received}")
  @simbuf.println("Average end-to-end delay: \{total_delay / received.to_double()}")
  @simbuf.to_string()
}