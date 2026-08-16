///|
test "uniform distribution range" {
  let rng = @random.new_rng()
  for _ in 0..<100 {
    let x = @random.uniform(rng, min=5.0, max=15.0)
    assert_true(x >= 5.0 && x < 15.0)
  }
}

///|
test "exponential distribution positive" {
  let rng = @random.new_rng()
  for _ in 0..<100 {
    let x = @random.exponential(rng, lambda=2.0)
    assert_true(x >= 0.0)
  }
}

///|
test "normal distribution finite" {
  let rng = @random.new_rng()
  for _ in 0..<100 {
    let x = @random.normal(rng, mean=0.0, std=1.0)
    assert_true(x == x)
  }
}

///|
test "poisson distribution non-negative" {
  let rng = @random.new_rng()
  for _ in 0..<100 {
    let k = @random.poisson(rng, lambda=5.0)
    assert_true(k >= 0)
  }
}

///|
test "bernoulli distribution" {
  let rng = @random.new_rng()
  let mut success = 0
  for _ in 0..<1000 {
    if @random.bernoulli(rng, p=0.5) {
      success += 1
    }
  }
  // 概率 0.5，1000 次试验，成功次数应在 400~600 范围内
  assert_true(success > 350 && success < 650)
}

///|
test "randint range" {
  let rng = @random.new_rng()
  for _ in 0..<100 {
    let k = @random.randint(rng, min=1, max=10)
    assert_true(k >= 1 && k <= 10)
  }
}
