///|
/// sim/equipment.mbt — 设备仿真模型 + 能耗计算
/// 分项计量: 曝气/提升/搅拌/污泥/加药/辅助

///|
/// 曝气系统能耗 (鼓风机)
pub fn energy_aeration(wq : WaterQuality, cfg : AAOConfig) -> Double {
  let q = wq.flow
  let cod_influent = wq.cod
  let nh4 = wq.nh4_n
  let o2_carbon = q * cod_influent * 0.001 * 1.1
  let o2_nitrif = q * nh4 * 0.001 * 4.57
  let o2_denit = q * nh4 * 0.001 * 4.57 * 0.6 * 2.86 / 4.57
  let o2_demand = max_d(o2_carbon + o2_nitrif - o2_denit, 0.0)
  let ote = 0.15 * (6.0 / (cfg.do_setpoint + 2.0))
  let air_demand = o2_demand / (ote * 0.28)
  let blower_power = air_demand * 60.0 / (3600.0 * 0.7)
  blower_power * 24.0
}

///|
/// 提升系统能耗 (提升泵)
pub fn energy_pumping(wq : WaterQuality) -> Double {
  let q = wq.flow
  let head = 8.0
  let pump_eff = 0.75
  let motor_eff = 0.92
  let power = 1000.0 * 9.81 * q / 3600.0 * head / (pump_eff * motor_eff) / 1000.0
  power * 24.0
}

///|
/// 搅拌系统能耗 (潜水搅拌机)
pub fn energy_mixing(wq : WaterQuality, cfg : AAOConfig) -> Double {
  let power_anaerobic = cfg.anaerobic_volume * 0.006
  let power_anoxic = cfg.anoxic_volume * 0.005
  let total_power = power_anaerobic + power_anoxic
  total_power * 24.0
}

///|
/// 污泥处理能耗 (浓缩+脱水)
pub fn energy_sludge(wq : WaterQuality, cfg : PlantConfig) -> Double {
  let bod_load = wq.flow * wq.bod5 * 0.001
  let y_obs = 0.5
  let sludge_mass = bod_load * y_obs
  let thickening_energy = sludge_mass * 0.01
  let dewatering_energy = sludge_mass * 0.03
  let return_pump_power = cfg.aao.waste_sludge_flow / 24.0 * 5.0 / (0.7 * 0.9) / 1000.0 * 1000.0 * 9.81 / 3600.0
  thickening_energy + dewatering_energy + return_pump_power * 24.0
}

///|
/// 加药系统能耗
pub fn energy_chemical(wq : WaterQuality, cfg : PlantConfig) -> Double {
  let pac_power = 0.5
  let carbon_power = 0.3
  (pac_power + carbon_power) * 24.0
}

///|
/// 辅助系统能耗
pub fn energy_other(wq : WaterQuality) -> Double {
  20.0 * 24.0
}

///|
/// 完整能耗分析
pub fn energy_analysis(wq : WaterQuality, cfg : PlantConfig) -> EnergyAnalysis {
  let e_aer = energy_aeration(wq, cfg.aao)
  let e_pump = energy_pumping(wq)
  let e_mix = energy_mixing(wq, cfg.aao)
  let e_sludge = energy_sludge(wq, cfg)
  let e_chem = energy_chemical(wq, cfg)
  let e_other = energy_other(wq)
  let total = e_aer + e_pump + e_mix + e_sludge + e_chem + e_other
  let daily_flow = wq.flow * 24.0
  let per_m3 = if daily_flow > 0.0 { total / daily_flow } else { 0.0 }
  let electricity_price = 0.65
  let pac_price = 2500.0
  let carbon_price = 3000.0
  let pam_price = 15000.0
  let cost_elec = total * electricity_price
  let pac_consumption = cfg.pac_dose * daily_flow * 0.001
  let carbon_consumption = cfg.carbon_dose * daily_flow * 0.001
  let pam_consumption = 0.5
  let cost_chem = pac_consumption * pac_price / 1000.0 +
                  carbon_consumption * carbon_price / 1000.0 +
                  pam_consumption * pam_price / 1000.0
  let cost_total = cost_elec + cost_chem
  let cost_per_m3 = if daily_flow > 0.0 { cost_total / daily_flow } else { 0.0 }
  {
    aeration: e_aer,
    pumping: e_pump,
    mixing: e_mix,
    sludge: e_sludge,
    chemical: e_chem,
    other: e_other,
    total,
    per_m3,
    cost_electricity: cost_elec,
    cost_chemical: cost_chem,
    cost_total,
    cost_per_m3,
  }
}

///|
/// 设备状态评估
pub(all) struct EquipmentStatus {
  name : String
  type_ : String
  status : String
  health : Double
  power : Double
  runtime : Double
} derive(Debug)

///|
/// 评估关键设备状态
pub fn evaluate_equipment(wq : WaterQuality, cfg : PlantConfig) -> Array[EquipmentStatus] {
  let result : Array[EquipmentStatus] = []
  let pump_power = energy_pumping(wq) / 24.0 / 3.0
  result.push({ name: "提升泵1#", type_: "离心泵", status: "running", health: 92.0, power: pump_power, runtime: 7200.0 })
  result.push({ name: "提升泵2#", type_: "离心泵", status: "running", health: 88.0, power: pump_power, runtime: 6800.0 })
  result.push({ name: "提升泵3#", type_: "离心泵", status: "running", health: 95.0, power: pump_power, runtime: 5000.0 })
  result.push({ name: "提升泵4#", type_: "离心泵", status: "standby", health: 90.0, power: 0.0, runtime: 0.0 })
  let blower_power = energy_aeration(wq, cfg.aao) / 24.0 / 2.0
  result.push({ name: "鼓风机1#", type_: "离心风机", status: "running", health: 85.0, power: blower_power, runtime: 8000.0 })
  result.push({ name: "鼓风机2#", type_: "离心风机", status: "running", health: 90.0, power: blower_power, runtime: 7500.0 })
  result.push({ name: "鼓风机3#", type_: "离心风机", status: "standby", health: 93.0, power: 0.0, runtime: 0.0 })
  let mixer_power = energy_mixing(wq, cfg.aao) / 24.0 / 4.0
  result.push({ name: "厌氧搅拌器1#", type_: "潜水搅拌机", status: "running", health: 88.0, power: mixer_power, runtime: 9000.0 })
  result.push({ name: "厌氧搅拌器2#", type_: "潜水搅拌机", status: "running", health: 91.0, power: mixer_power, runtime: 8500.0 })
  result.push({ name: "缺氧搅拌器1#", type_: "潜水搅拌机", status: "running", health: 87.0, power: mixer_power, runtime: 8800.0 })
  result.push({ name: "缺氧搅拌器2#", type_: "潜水搅拌机", status: "running", health: 89.0, power: mixer_power, runtime: 8200.0 })
  result.push({ name: "内回流泵1#", type_: "潜水泵", status: "running", health: 90.0, power: 15.0, runtime: 7000.0 })
  result.push({ name: "内回流泵2#", type_: "潜水泵", status: "running", health: 85.0, power: 15.0, runtime: 6500.0 })
  result.push({ name: "板框脱水机1#", type_: "脱水机", status: "running", health: 82.0, power: 22.0, runtime: 6000.0 })
  result.push({ name: "板框脱水机2#", type_: "脱水机", status: "standby", health: 90.0, power: 0.0, runtime: 0.0 })
  result
}
