test "simbuf basic" {
  @simbuf.clear()
  @simbuf.println("hello")
  @simbuf.println("world")
  assert_eq(@simbuf.to_string(), "hello\nworld")
  assert_eq(@simbuf.line_count(), 2)
}

test "simbuf clear" {
  @simbuf.println("a")
  @simbuf.clear()
  assert_eq(@simbuf.line_count(), 0)
  assert_eq(@simbuf.to_string(), "")
}

test "simbuf print" {
  @simbuf.clear()
  @simbuf.print("foo")
  @simbuf.print("bar")
  assert_eq(@simbuf.to_string(), "foobar")
}
