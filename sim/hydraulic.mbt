///|
/// sim/hydraulic.mbt — 水力仿真模型
/// 全流程9个处理单元的流量分配、HRT计算、水量平衡
/// 基于质量守恒 + 经验去除率模型

///|
/// 格栅处理 — 去除大颗粒悬浮物
pub fn process_screen(wq : WaterQuality) -> WaterQuality {
  {
    ..wq,
    ss: wq.ss * 0.85,
    cod: wq.cod * 0.95,
    bod5: wq.bod5 * 0.97,
  }
}

///|
/// 沉砂池处理 — 去除无机砂粒
pub fn process_grit(wq : WaterQuality) -> WaterQuality {
  {
    ..wq,
    ss: wq.ss * 0.92,
  }
}

///|
/// 初沉池处理 — 沉淀悬浮固体
pub fn process_primary_clarifier(wq : WaterQuality) -> WaterQuality {
  let temp_factor = temp_correction(1.0, 0.95, wq.temperature)
  let ss_removal = clamp(0.55 * temp_factor, 0.35, 0.65)
  let cod_removal = clamp(0.30 * temp_factor, 0.20, 0.38)
  let bod_removal = clamp(0.30 * temp_factor, 0.20, 0.38)
  {
    ..wq,
    ss: wq.ss * (1.0 - ss_removal),
    cod: wq.cod * (1.0 - cod_removal),
    bod5: wq.bod5 * (1.0 - bod_removal),
    tn: wq.tn * (1.0 - 0.08),
    tp: wq.tp * (1.0 - 0.12),
    po4_p: wq.po4_p * (1.0 - 0.10),
    nh4_n: wq.nh4_n * 1.02,
  }
}

///|
/// 二沉池处理 — 污泥沉淀, 出水SS极低
pub fn process_secondary_clarifier(wq : WaterQuality, cfg : AAOConfig) -> WaterQuality {
  let temp_factor = temp_correction(1.0, 0.97, wq.temperature)
  let ss_removal = clamp(0.97 * temp_factor, 0.90, 0.995)
  let particulate_cod = wq.cod * 0.6
  let cod_removed = particulate_cod * ss_removal * 0.5
  let tp_removed = wq.tp * ss_removal * 0.25
  let tn_removed = wq.tn * ss_removal * 0.12
  {
    ..wq,
    ss: wq.ss * (1.0 - ss_removal),
    cod: wq.cod - cod_removed,
    tp: wq.tp - tp_removed,
    tn: wq.tn - tn_removed,
    nh4_n: wq.nh4_n * (1.0 - ss_removal * 0.05),
    po4_p: wq.po4_p * (1.0 - ss_removal * 0.1),
    mlss: 0.0,
    do_value: wq.do_value * 0.5,
  }
}

///|
/// 深床滤池处理 — SS深度去除 + 化学除磷
pub fn process_deep_filter(wq : WaterQuality, pac_dose : Double) -> WaterQuality {
  let ss_removal = 0.75
  let tp_removal_chem = if wq.tp > 0.0 && pac_dose > 0.0 {
    clamp(pac_dose / (wq.tp * 2.0) * 0.9, 0.0, 0.92)
  } else {
    0.15
  }
  let cod_removal = 0.10
  let tn_removal = 0.25
  {
    ..wq,
    ss: wq.ss * (1.0 - ss_removal),
    tp: wq.tp * (1.0 - tp_removal_chem),
    po4_p: wq.po4_p * (1.0 - tp_removal_chem),
    cod: wq.cod * (1.0 - cod_removal),
    bod5: wq.bod5 * (1.0 - 0.05),
    tn: wq.tn * (1.0 - tn_removal),
  }
}

///|
/// 紫外消毒 — 灭活粪大肠菌群
pub fn process_uv_disinfection(wq : WaterQuality, uv_dose : Double) -> WaterQuality {
  {
    ..wq,
    ss: wq.ss * 0.99,
  }
}

///|
/// 计算HRT (水力停留时间)
pub fn calc_hrt(volume : Double, flow : Double) -> Double {
  if flow > 0.0 { volume / flow } else { 0.0 }
}

///|
/// 混合两股水流 — 质量加权平均
pub fn mix_flows(wq1 : WaterQuality, flow1 : Double, wq2 : WaterQuality, flow2 : Double) -> WaterQuality {
  let total = flow1 + flow2
  if total <= 0.0 {
    return wq1
  }
  let r1 = flow1 / total
  let r2 = flow2 / total
  {
    cod: wq1.cod * r1 + wq2.cod * r2,
    bod5: wq1.bod5 * r1 + wq2.bod5 * r2,
    nh4_n: wq1.nh4_n * r1 + wq2.nh4_n * r2,
    no3_n: wq1.no3_n * r1 + wq2.no3_n * r2,
    tn: wq1.tn * r1 + wq2.tn * r2,
    tp: wq1.tp * r1 + wq2.tp * r2,
    po4_p: wq1.po4_p * r1 + wq2.po4_p * r2,
    ss: wq1.ss * r1 + wq2.ss * r2,
    mlss: wq1.mlss * r1 + wq2.mlss * r2,
    do_value: wq1.do_value * r1 + wq2.do_value * r2,
    temperature: wq1.temperature * r1 + wq2.temperature * r2,
    flow: total,
    ph: wq1.ph * r1 + wq2.ph * r2,
    alkalinity: wq1.alkalinity * r1 + wq2.alkalinity * r2,
  }
}

///|
/// 水量平衡校验
pub fn check_flow_balance(influent : WaterQuality, effluent : WaterQuality, cfg : PlantConfig) -> Double {
  let q_in = influent.flow
  let q_out = effluent.flow
  let q_waste = cfg.aao.waste_sludge_flow / 24.0
  let q_backwash = q_in * 0.02
  let q_evap = q_in * 0.003
  let balance = q_in - q_out - q_waste - q_backwash - q_evap
  if q_in > 0.0 { abs_d(balance) / q_in } else { 0.0 }
}

///|
/// F/M比 (食微比)
pub fn calc_fm_ratio(wq : WaterQuality, cfg : AAOConfig) -> Double {
  let total_volume = cfg.anaerobic_volume + cfg.anoxic_volume + cfg.oxic_volume
  let mlss = cfg.mlss_target
  if total_volume > 0.0 && mlss > 0.0 {
    (wq.flow * wq.bod5) / (total_volume * mlss / 1000.0)
  } else {
    0.0
  }
}

///|
/// 污泥负荷
pub fn calc_sludge_loading(wq : WaterQuality, cfg : AAOConfig) -> Double {
  calc_fm_ratio(wq, cfg)
}

///|
/// 容积负荷
pub fn calc_volume_loading(wq : WaterQuality, cfg : AAOConfig) -> Double {
  let total_volume = cfg.anaerobic_volume + cfg.anoxic_volume + cfg.oxic_volume
  if total_volume > 0.0 {
    (wq.flow * wq.bod5) / total_volume
  } else {
    0.0
  }
}
