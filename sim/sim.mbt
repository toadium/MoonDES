///|
/// sim/sim.mbt — 仿真编排器
/// steady_state: 稳态仿真
/// step: 动态推进一步
/// run_dynamic: 动态仿真N步
/// export_json: 导出结果JSON

///|
/// 稳态仿真 — 给定进水和配置, 计算全流程出水
pub fn steady_state(influent : WaterQuality, cfg : PlantConfig) -> SimResult {
  let w1 = process_screen(influent)
  let w2 = process_grit(w1)
  let w3 = process_primary_clarifier(w2)
  let (_, w4_anaerobic, w4_anoxic, w4_oxic) = aao_reactor(w3, cfg.aao)
  let w5 = process_secondary_clarifier(w4_oxic, cfg.aao)
  let w6 = process_deep_filter(w5, cfg.pac_dose)
  let w7 = process_uv_disinfection(w6, cfg.uv_dose)
  let removal_cod = if influent.cod > 0.0 {
    (influent.cod - w7.cod) / influent.cod * 100.0
  } else { 0.0 }
  let removal_nh4 = if influent.nh4_n > 0.0 {
    (influent.nh4_n - w7.nh4_n) / influent.nh4_n * 100.0
  } else { 0.0 }
  let removal_tn = if influent.tn > 0.0 {
    (influent.tn - w7.tn) / influent.tn * 100.0
  } else { 0.0 }
  let removal_tp = if influent.tp > 0.0 {
    (influent.tp - w7.tp) / influent.tp * 100.0
  } else { 0.0 }
  let removal_ss = if influent.ss > 0.0 {
    (influent.ss - w7.ss) / influent.ss * 100.0
  } else { 0.0 }
  let ea = energy_analysis(w3, cfg)
  let compliance = w7.cod <= 50.0 && w7.nh4_n <= 5.0 && w7.tn <= 15.0 &&
                   w7.tp <= 0.5 && w7.ss <= 10.0
  let flow_balance = check_flow_balance(influent, w7, cfg)
  {
    influent,
    effluent: w7,
    after_screen: w1,
    after_grit: w2,
    after_primary: w3,
    after_anaerobic: w4_anaerobic,
    after_anoxic: w4_anoxic,
    after_oxic: w4_oxic,
    after_secondary: w5,
    after_filter: w6,
    after_uv: w7,
    removal_cod,
    removal_nh4,
    removal_tn,
    removal_tp,
    removal_ss,
    energy_aeration: ea.aeration,
    energy_pumping: ea.pumping,
    energy_mixing: ea.mixing,
    energy_sludge: ea.sludge,
    energy_other: ea.chemical + ea.other,
    energy_total: ea.total,
    energy_per_m3: ea.per_m3,
    compliance,
    flow_balance,
  }
}

///|
/// 动态推进一步
pub fn step(state : SimState, cfg : PlantConfig, dt : Double) -> SimState {
  let result = steady_state(state.influent, cfg)
  let new_time = state.time + dt * state.speed
  let new_energy = state.energy_total + result.energy_total * dt / 24.0
  let daily_flow = state.influent.flow * 24.0
  let new_cost = state.cost_total + result.energy_per_m3 * daily_flow * dt / 24.0 * 0.65
  {
    time: new_time,
    influent: state.influent,
    effluent: result.effluent,
    reactor: result.after_oxic,
    energy_total: new_energy,
    cost_total: new_cost,
    running: state.running,
    speed: state.speed,
    step_count: state.step_count + 1,
  }
}

///|
/// 动态仿真N步
pub fn run_dynamic(influent : WaterQuality, cfg : PlantConfig, steps : Int, dt : Double) -> Array[SimState] {
  let mut state : SimState = {
    ..default_sim_state(),
    influent,
    running: true,
  }
  let history : Array[SimState] = []
  for _ in 0..<steps {
    state = step(state, cfg, dt)
    history.push(state)
  }
  history
}

///|
/// AI优化建议
pub fn optimize_suggestions(result : SimResult, cfg : PlantConfig) -> Array[(String, Double, Double, String)] {
  let suggestions : Array[(String, Double, Double, String)] = []
  if result.effluent.nh4_n > 3.0 && cfg.aao.do_setpoint < 3.0 {
    suggestions.push(("好氧区DO", cfg.aao.do_setpoint, cfg.aao.do_setpoint + 0.5,
      "出水氨氮偏高, 建议提高DO增强硝化"))
  } else if result.effluent.nh4_n < 1.0 && cfg.aao.do_setpoint > 1.5 {
    suggestions.push(("好氧区DO", cfg.aao.do_setpoint, cfg.aao.do_setpoint - 0.3,
      "出水氨氮已很低, 可降低DO节省曝气能耗"))
  }
  if result.effluent.tn > 12.0 && cfg.aao.internal_recycle_ratio < 4.0 {
    suggestions.push(("内回流比", cfg.aao.internal_recycle_ratio, cfg.aao.internal_recycle_ratio + 0.5,
      "出水TN偏高, 建议提高内回流增强反硝化"))
  }
  if result.effluent.nh4_n > 4.0 && cfg.aao.srt < 20.0 {
    suggestions.push(("污泥龄SRT", cfg.aao.srt, cfg.aao.srt + 2.0,
      "氨氮超标, 建议延长SRT保障硝化菌"))
  }
  if result.removal_cod < 80.0 && cfg.aao.mlss_target < 4000.0 {
    suggestions.push(("MLSS", cfg.aao.mlss_target, cfg.aao.mlss_target + 500.0,
      "COD去除率偏低, 建议提高MLSS"))
  }
  if result.effluent.ss > 8.0 && cfg.aao.external_recycle_ratio < 1.2 {
    suggestions.push(("外回流比", cfg.aao.external_recycle_ratio, cfg.aao.external_recycle_ratio + 0.2,
      "出水SS偏高, 建议提高外回流改善沉降"))
  }
  if result.effluent.tp > 0.4 && cfg.pac_dose < 5.0 {
    suggestions.push(("PAC投加量", cfg.pac_dose, cfg.pac_dose + 2.0,
      "出水TP偏高, 建议增加PAC化学除磷"))
  }
  suggestions
}

///|
/// 达标判定 — 一级A标准
pub fn check_compliance(wq : WaterQuality) -> Bool {
  wq.cod <= 50.0 && wq.nh4_n <= 5.0 && wq.tn <= 15.0 &&
  wq.tp <= 0.5 && wq.ss <= 10.0
}

///|
/// 工艺健康度评分 (0~100)
pub fn health_score(result : SimResult) -> Double {
  let mut score = 100.0
  if result.effluent.cod > 50.0 { score -= (result.effluent.cod - 50.0) * 0.5 }
  if result.effluent.nh4_n > 5.0 { score -= (result.effluent.nh4_n - 5.0) * 2.0 }
  if result.effluent.tn > 15.0 { score -= (result.effluent.tn - 15.0) * 1.5 }
  if result.effluent.tp > 0.5 { score -= (result.effluent.tp - 0.5) * 20.0 }
  if result.effluent.ss > 10.0 { score -= (result.effluent.ss - 10.0) * 1.0 }
  if result.energy_per_m3 > 0.25 { score -= (result.energy_per_m3 - 0.25) * 50.0 }
  if result.flow_balance > 0.01 { score -= result.flow_balance * 100.0 }
  clamp(score, 0.0, 100.0)
}

// ============================================================================
// JSON导出
// ============================================================================

///|
pub fn wq_json(wq : WaterQuality) -> String {
  "{\"cod\":\{wq.cod},\"bod5\":\{wq.bod5},\"nh4_n\":\{wq.nh4_n},\"no3_n\":\{wq.no3_n},\"tn\":\{wq.tn},\"tp\":\{wq.tp},\"po4_p\":\{wq.po4_p},\"ss\":\{wq.ss},\"mlss\":\{wq.mlss},\"do\":\{wq.do_value},\"temp\":\{wq.temperature},\"flow\":\{wq.flow},\"ph\":\{wq.ph},\"alkalinity\":\{wq.alkalinity}}"
}

///|
pub fn sim_result_json(result : SimResult) -> String {
  "{\"influent\":\{wq_json(result.influent)},\"effluent\":\{wq_json(result.effluent)},\"after_screen\":\{wq_json(result.after_screen)},\"after_grit\":\{wq_json(result.after_grit)},\"after_primary\":\{wq_json(result.after_primary)},\"after_anaerobic\":\{wq_json(result.after_anaerobic)},\"after_anoxic\":\{wq_json(result.after_anoxic)},\"after_oxic\":\{wq_json(result.after_oxic)},\"after_secondary\":\{wq_json(result.after_secondary)},\"after_filter\":\{wq_json(result.after_filter)},\"after_uv\":\{wq_json(result.after_uv)},\"removal\":{\"cod\":\{result.removal_cod},\"nh4\":\{result.removal_nh4},\"tn\":\{result.removal_tn},\"tp\":\{result.removal_tp},\"ss\":\{result.removal_ss}},\"energy\":{\"aeration\":\{result.energy_aeration},\"pumping\":\{result.energy_pumping},\"mixing\":\{result.energy_mixing},\"sludge\":\{result.energy_sludge},\"other\":\{result.energy_other},\"total\":\{result.energy_total},\"per_m3\":\{result.energy_per_m3}},\"compliance\":\{result.compliance},\"flow_balance\":\{result.flow_balance},\"health_score\":\{health_score(result)}}"
}

///|
pub fn energy_json(ea : EnergyAnalysis) -> String {
  "{\"aeration\":\{ea.aeration},\"pumping\":\{ea.pumping},\"mixing\":\{ea.mixing},\"sludge\":\{ea.sludge},\"chemical\":\{ea.chemical},\"other\":\{ea.other},\"total\":\{ea.total},\"per_m3\":\{ea.per_m3},\"cost_electricity\":\{ea.cost_electricity},\"cost_chemical\":\{ea.cost_chemical},\"cost_total\":\{ea.cost_total},\"cost_per_m3\":\{ea.cost_per_m3}}"
}

///|
pub fn scenarios_json() -> String {
  let scenarios = load_scenarios()
  let items : Array[String] = []
  for s in scenarios {
    items.push("{\"id\":\{s.id},\"name\":\{s.name.to_json().stringify()},\"description\":\{s.description.to_json().stringify()},\"category\":\{s.category.to_json().stringify()},\"flow_factor\":\{s.flow_factor},\"cod_factor\":\{s.cod_factor},\"nh4_factor\":\{s.nh4_factor},\"tn_factor\":\{s.tn_factor},\"tp_factor\":\{s.tp_factor},\"temp_offset\":\{s.temp_offset},\"duration\":\{s.duration}}")
  }
  "[\{items.join(", ")}]"
}

///|
pub fn faults_json() -> String {
  let faults = fault_scenarios()
  let items : Array[String] = []
  for f in faults {
    items.push("{\"id\":\{f.id},\"name\":\{f.name.to_json().stringify()},\"category\":\{f.category.to_json().stringify()},\"severity\":\{f.severity.to_json().stringify()},\"description\":\{f.description.to_json().stringify()},\"affected_unit\":\{f.affected_unit.to_json().stringify()},\"impact_cod\":\{f.impact_cod},\"impact_nh4\":\{f.impact_nh4},\"impact_tp\":\{f.impact_tp}}")
  }
  "[\{items.join(", ")}]"
}

///|
pub fn suggestions_json(suggestions : Array[(String, Double, Double, String)]) -> String {
  let items : Array[String] = []
  for s in suggestions {
    items.push("{\"param\":\{s.0.to_json().stringify()},\"current\":\{s.1},\"suggested\":\{s.2},\"reason\":\{s.3.to_json().stringify()}}")
  }
  "[\{items.join(", ")}]"
}

///|
pub fn equipment_json(equipments : Array[EquipmentStatus]) -> String {
  let items : Array[String] = []
  for e in equipments {
    items.push("{\"name\":\{e.name.to_json().stringify()},\"type\":\{e.type_.to_json().stringify()},\"status\":\{e.status.to_json().stringify()},\"health\":\{e.health},\"power\":\{e.power},\"runtime\":\{e.runtime}}")
  }
  "[\{items.join(", ")}]"
}
