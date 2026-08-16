///|
test "resource pool basic" {
  let pool = @resource.new_pool(name="servers", size=3)
  inspect(pool.size(), content="3")
  inspect(pool.available_count(), content="3")
}

///|
test "resource pool request release" {
  let pool = @resource.new_pool(name="servers", size=2)
  let mut got1 = false
  let mut got2 = false
  let mut got3 = false
  ignore(pool.request(pid=1, callback=fn() { got1 = true }))
  ignore(pool.request(pid=2, callback=fn() { got2 = true }))
  ignore(pool.request(pid=3, callback=fn() { got3 = true }))
  assert_true(got1)
  assert_true(got2)
  assert_true(!got3)
  inspect(pool.available_count(), content="0")
  inspect(pool.holder_slot(pid=1), content="0")
  inspect(pool.holder_slot(pid=2), content="1")
  inspect(pool.holder_slot(pid=3), content="-1")
  pool.release(pid=1)
  inspect(pool.available_count(), content="1")
  inspect(pool.holder_slot(pid=1), content="-1")
}

///|
test "reentrant resource basic" {
  let r = @resource.new_reentrant(name="lock")
  inspect(r.is_free(), content="true")
  let mut got1 = false
  ignore(r.request(pid=1, callback=fn() { got1 = true }))
  assert_true(got1)
  inspect(r.is_free(), content="false")
  inspect(r.hold_count_of(pid=1), content="1")
}

///|
test "reentrant resource multiple acquire" {
  let r = @resource.new_reentrant(name="lock")
  let mut count = 0
  ignore(r.request(pid=1, callback=fn() { count += 1 }))
  ignore(r.request(pid=1, callback=fn() { count += 1 }))
  ignore(r.request(pid=1, callback=fn() { count += 1 }))
  inspect(count, content="3")
  inspect(r.hold_count_of(pid=1), content="3")
  r.release(pid=1)
  inspect(r.hold_count_of(pid=1), content="2")
  r.release(pid=1)
  inspect(r.hold_count_of(pid=1), content="1")
  r.release(pid=1)
  inspect(r.is_free(), content="true")
}

///|
test "reentrant resource queue" {
  let r = @resource.new_reentrant(name="lock")
  let mut got2 = false
  ignore(r.request(pid=1, callback=fn() { () }))
  ignore(r.request(pid=2, callback=fn() { got2 = true }))
  assert_true(!got2)
  inspect(r.queue_length(), content="1")
  r.release(pid=1)
  assert_true(got2)
  inspect(r.queue_length(), content="0")
}

///|
test "resource group basic" {
  let g = @resource.new_group()
  g.add(@resource.new_exclusive(name="machine"))
  g.add(@resource.new_exclusive(name="worker"))
  g.add(@resource.new_exclusive(name="tool"))
  inspect(g.size(), content="3")
  inspect(g.acquired_count(), content="0")
}

///|
test "resource group request all" {
  let g = @resource.new_group()
  g.add(@resource.new_exclusive(name="machine"))
  g.add(@resource.new_exclusive(name="worker"))
  let mut got = false
  let result = g.request_all(pid=1, callback=fn() { got = true })
  assert_true(result)
  assert_true(got)
  inspect(g.acquired_count(), content="2")
  g.release_all()
  inspect(g.acquired_count(), content="0")
}

///|
test "resource group atomic fail" {
  let g = @resource.new_group()
  let r1 = @resource.new_exclusive(name="r1")
  let r2 = @resource.new_exclusive(name="r2")
  g.add(r1)
  g.add(r2)
  // 先占用 r1
  ignore(r1.request(pid=99, callback=fn() { () }))
  // request_all 应失败（原子语义）
  let mut got = false
  let result = g.request_all(pid=1, callback=fn() { got = true })
  assert_true(!result)
  assert_true(!got)
  inspect(g.acquired_count(), content="0")
}
