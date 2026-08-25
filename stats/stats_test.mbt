///|
test "sum basic" {
  inspect(@stats.sum([1.0, 2.0, 3.0, 4.0, 5.0]), content="15")
  inspect(@stats.sum([]), content="0")
}

///|
test "mean basic" {
  inspect(@stats.mean([1.0, 2.0, 3.0, 4.0, 5.0]), content="3")
  inspect(@stats.mean([]), content="0")
}

///|
test "variance basic" {
  // 方差 of [1,2,3,4,5] = 2.5
  inspect(@stats.variance([1.0, 2.0, 3.0, 4.0, 5.0]), content="2.5")
}

///|
test "stddev basic" {
  let s = @stats.stddev([1.0, 2.0, 3.0, 4.0, 5.0])
  // sqrt(2.5) ≈ 1.5811388300841898
  assert_true(s > 1.58 && s < 1.59)
}

///|
test "min max basic" {
  inspect(@stats.min([3.0, 1.0, 4.0, 1.0, 5.0]), content="1")
  inspect(@stats.max([3.0, 1.0, 4.0, 1.0, 5.0]), content="5")
}

///|
test "histogram basic" {
  let data = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
  let hist = @stats.histogram(data, 5)
  debug_inspect(hist, content="[2, 2, 2, 2, 2]")
}

///|
test "summary basic" {
  let s = @stats.summary([1.0, 2.0, 3.0, 4.0, 5.0])
  inspect(s.count, content="5")
  inspect(s.mean, content="3")
  inspect(s.min, content="1")
  inspect(s.max, content="5")
  inspect(s.sum, content="15")
}

///|
test "covariance basic" {
  let x = [1.0, 2.0, 3.0, 4.0, 5.0]
  let y = [2.0, 4.0, 6.0, 8.0, 10.0]
  // y = 2x, covariance = 5
  inspect(@stats.covariance(x, y), content="5")
}

///|
test "correlation basic" {
  let x = [1.0, 2.0, 3.0, 4.0, 5.0]
  let y = [2.0, 4.0, 6.0, 8.0, 10.0]
  // 完全线性相关，相关系数 = 1
  let r = @stats.correlation(x, y)
  assert_true(r > 0.99 && r <= 1.0)
}
