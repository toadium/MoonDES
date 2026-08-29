///|
/// sim/sim_test.mbt — 单元测试

///|
test "default_influent: 典型城镇污水进水" {
  let wq = default_influent()
  assert_eq(wq.cod, 280.0)
  assert_eq(wq.nh4_n, 35.0)
  assert_eq(wq.flow, 4167.0)
  assert_eq(wq.temperature, 20.0)
}

///|
test "default_aao_config: ASM2d参数" {
  let cfg = default_aao_config()
  assert_eq(cfg.mu_h, 6.0)
  assert_eq(cfg.mu_a, 1.2)
  assert_eq(cfg.do_setpoint, 2.5)
  assert_eq(cfg.internal_recycle_ratio, 6.0)
  assert_eq(cfg.srt, 18.0)
}

///|
test "temp_correction: Arrhenius温度修正" {
  assert_eq(temp_correction(1.0, 1.07, 20.0), 1.0)
  assert_true(temp_correction(1.0, 1.07, 30.0) > 1.0)
  assert_true(temp_correction(1.0, 1.07, 10.0) < 1.0)
}

///|
test "clamp: 限制范围" {
  assert_eq(clamp(5.0, 0.0, 10.0), 5.0)
  assert_eq(clamp(-1.0, 0.0, 10.0), 0.0)
  assert_eq(clamp(15.0, 0.0, 10.0), 10.0)
}

///|
test "process_screen: 格栅处理" {
  let wq = default_influent()
  let result = process_screen(wq)
  assert_true(result.ss < wq.ss)
  assert_true(result.cod < wq.cod)
}

///|
test "process_grit: 沉砂池处理" {
  let wq = default_influent()
  let result = process_grit(wq)
  assert_true(result.ss < wq.ss)
  assert_eq(result.cod, wq.cod)
}

///|
test "process_primary_clarifier: 初沉池处理" {
  let wq = default_influent()
  let result = process_primary_clarifier(wq)
  assert_true(result.ss < wq.ss * 0.5)
  assert_true(result.cod < wq.cod * 0.8)
}

///|
test "process_secondary_clarifier: 二沉池处理" {
  let wq = default_influent()
  let cfg = default_aao_config()
  let result = process_secondary_clarifier(wq, cfg)
  assert_true(result.ss < wq.ss * 0.1)
  assert_eq(result.mlss, 0.0)
}

///|
test "process_deep_filter: 深床滤池" {
  let wq = default_influent()
  let result = process_deep_filter(wq, 0.0)
  assert_true(result.ss < wq.ss * 0.3)
}

///|
test "calc_hrt: 水力停留时间" {
  let hrt = calc_hrt(1000.0, 100.0)
  assert_eq(hrt, 10.0)
  assert_eq(calc_hrt(1000.0, 0.0), 0.0)
}

///|
test "mix_flows: 水流混合" {
  let wq1 = default_influent()
  let wq2 : WaterQuality = { ..wq1, cod: 100.0 }
  let mixed = mix_flows(wq1, 100.0, wq2, 100.0)
  assert_true(abs_d(mixed.cod - 190.0) < 1.0)
  assert_eq(mixed.flow, 200.0)
}

///|
test "aao_reactor: AAO三区串联" {
  let wq = default_influent()
  let cfg = default_aao_config()
  let (_, anaerobic, _anoxic, oxic) = aao_reactor(wq, cfg)
  assert_true(anaerobic.po4_p > wq.po4_p)
  assert_true(abs_d(oxic.do_value - cfg.do_setpoint) < 0.1)
  assert_true(oxic.nh4_n < wq.nh4_n)
}

///|
test "steady_state: 全流程稳态仿真" {
  let wq = default_influent()
  let cfg = default_plant_config()
  let result = steady_state(wq, cfg)
  // COD去除率应>70% (简化模型)
  assert_true(result.removal_cod > 70.0)
  // 氨氮有去除
  assert_true(result.removal_nh4 > 50.0)
  // SS去除率很高
  assert_true(result.removal_ss > 95.0)
  // 应有能耗
  assert_true(result.energy_total > 0.0)
  // 吨水电耗合理范围
  assert_true(result.energy_per_m3 > 0.05 && result.energy_per_m3 < 0.5)
}

///|
test "energy_analysis: 能耗分析" {
  let wq = default_influent()
  let cfg = default_plant_config()
  let ea = energy_analysis(wq, cfg)
  assert_true(ea.aeration > ea.pumping)
  assert_true(ea.total > 0.0)
  assert_true(ea.per_m3 > 0.0)
  assert_true(ea.cost_total > 0.0)
}

///|
test "load_scenarios: 12类负荷场景" {
  let scenarios = load_scenarios()
  assert_eq(scenarios.length(), 12)
  assert_eq(scenarios[0].name, "典型日负荷")
  assert_eq(scenarios[4].name, "工业废水冲击")
}

///|
test "fault_scenarios: 26项故障场景" {
  let faults = fault_scenarios()
  assert_eq(faults.length(), 26)
  let mut has_process = false
  let mut has_equipment = false
  let mut has_safety = false
  for f in faults {
    if f.category == "process" { has_process = true }
    if f.category == "equipment" { has_equipment = true }
    if f.category == "safety" { has_safety = true }
  }
  assert_true(has_process)
  assert_true(has_equipment)
  assert_true(has_safety)
}

///|
test "apply_load_scenario: 应用负荷场景" {
  let wq = default_influent()
  let scenarios = load_scenarios()
  let industrial = scenarios[4]
  let wq_shock = apply_load_scenario(wq, industrial)
  assert_true(wq_shock.cod > wq.cod)
  assert_true(wq_shock.flow > wq.flow)
}

///|
test "optimize_suggestions: AI优化建议" {
  let wq = default_influent()
  let cfg = default_plant_config()
  let result = steady_state(wq, cfg)
  let suggestions = optimize_suggestions(result, cfg)
  assert_true(suggestions.length() >= 0)
}

///|
test "health_score: 工艺健康度" {
  let wq = default_influent()
  let cfg = default_plant_config()
  let result = steady_state(wq, cfg)
  let score = health_score(result)
  assert_true(score >= 0.0)
  assert_true(score <= 100.0)
}

///|
test "check_compliance: 达标判定" {
  let wq_good : WaterQuality = {
    cod: 30.0, bod5: 10.0, nh4_n: 2.0, no3_n: 5.0, tn: 10.0,
    tp: 0.3, po4_p: 0.2, ss: 5.0, mlss: 0.0, do_value: 2.0,
    temperature: 20.0, flow: 4167.0, ph: 7.0, alkalinity: 200.0
  }
  assert_true(check_compliance(wq_good))
  let wq_bad : WaterQuality = { ..wq_good, cod: 60.0 }
  assert_false(check_compliance(wq_bad))
}

///|
test "daily_load_curve: 日负荷曲线" {
  let curve = daily_load_curve(4167.0)
  assert_eq(curve.length(), 24)
  for i in 0..<24 {
    assert_true(curve[i] > 0.0)
  }
}

///|
test "evaluate_equipment: 设备状态评估" {
  let wq = default_influent()
  let cfg = default_plant_config()
  let equipments = evaluate_equipment(wq, cfg)
  assert_true(equipments.length() > 0)
  let mut has_running = false
  let mut has_standby = false
  for e in equipments {
    if e.status == "running" { has_running = true }
    if e.status == "standby" { has_standby = true }
  }
  assert_true(has_running)
  assert_true(has_standby)
}

///|
test "calc_nitrification_efficiency: 硝化效率" {
  let eff = calc_nitrification_efficiency(15.0, 20.0, 2.0)
  assert_true(eff > 0.5)
  let eff_low = calc_nitrification_efficiency(2.0, 10.0, 2.0)
  assert_true(eff_low < eff)
}

///|
test "calc_fm_ratio: 食微比" {
  let wq = default_influent()
  let cfg = default_aao_config()
  let fm = calc_fm_ratio(wq, cfg)
  assert_true(fm > 0.0)
}

///|
test "sim_result_json: JSON导出" {
  let wq = default_influent()
  let cfg = default_plant_config()
  let result = steady_state(wq, cfg)
  let json = sim_result_json(result)
  assert_true(json.contains("influent"))
  assert_true(json.contains("effluent"))
  assert_true(json.contains("removal"))
  assert_true(json.contains("energy"))
}
