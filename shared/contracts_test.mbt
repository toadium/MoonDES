test "shared example list" {
  let list = example_list()
  assert_eq(list.total, 19)
  assert_true(list.examples.length() == 19)
}

test "shared find example" {
  let ex = find_example("forest_fire")
  assert_true(ex is Some(_))
  let ex2 = find_example("nonexistent")
  assert_true(ex2 is None)
}

test "shared request to_json" {
  let req = SimulationRequest::{ name: "hello_des", params: "{}" }
  let json = req.to_json().stringify()
  assert_true(json.contains("hello_des"))
}

test "shared response from_json" {
  let resp = SimulationResponse::{
    name: "test",
    output: "hello",
    duration_ms: 10,
    success: true,
    error: None,
  }
  let json = resp.to_json()
  let parsed : SimulationResponse = @json.from_json(json)
  assert_eq(parsed.name, "test")
  assert_eq(parsed.output, "hello")
  assert_true(parsed.success)
}
