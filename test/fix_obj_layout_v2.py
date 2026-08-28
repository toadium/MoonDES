#!/usr/bin/env python3
"""
修复 OBJ 文件 V2 — 优化厂区布置，避免重叠，保持厂区内

厂区范围: X=[-40, 40], Z=[-30, 30]
水流方向: X 负→正（西→东）

分区:
  北侧 (Z<0):  办公/实验/配电/加药 + 污泥处理
  中央 (Z≈0):  主处理构筑物沿水流方向
  南侧 (Z>0):  曝气/搅拌/鼓风/维修/仓库/门卫
"""

import sys

# 优化后的布局 — 考虑构筑物实际尺寸，拉开间距
LAYOUT = {
    # 一级处理 — 西侧，沿水流方向
    0:  (-35, 0, 0),      # 进水检查井 (80×60 大平面, 保持原位)
    1:  (-32, 0, 0),      # 粗格栅间 (70×5 长条)
    2:  (-28, 0, 0),      # 细格栅间 (5×50 长条)
    3:  (-22, 0, 0),      # 提升泵房 (3×3)
    4:  (-17, 0, 0),      # 曝气沉砂池 (3.5×3)
    5:  (-12, 0, 0),      # 初沉池 (3.5×3)

    # 二级处理 — AAO 区，中央
    6:  (-5, 0, -8),      # 缺氧池 (5×5) — 北侧
    7:  (2, 0, -8),       # 厌氧池 (8×6)
    8:  (10, 0, -8),      # 好氧池 (10×2, 10m高)
    9:  (18, 0, -10),     # 接触区 (10×12) — 东北
    10: (18, 0, 10),      # 二沉池 (9×12) — 东南
    11: (10, 0, 10),      # 曝气器 (20×12) — 南侧
    12: (-5, 0, 10),      # 搅拌机 (6×12) — 南侧

    # 三级处理 — 东侧
    13: (25, 0, -8),      # 深床滤池 (11×2, 11m高)
    14: (30, 0, 0),       # 紫外消毒渠 (11×2, 11m高)
    15: (35, 0, -8),      # 清水池 (5×5)
    16: (38, 0, 0),       # 出水计量槽 (5×5)

    # 污泥处理 — 东北角
    17: (28, 0, -20),     # 污泥浓缩池 (6×4)
    18: (35, 0, -20),     # 污泥储池 (8×8)
    19: (28, 0, -26),     # 脱水机房 (8×2)
    20: (35, 0, -26),     # 污泥干化间 (8×2)

    # 辅助建筑
    21: (15, 0, 22),      # 鼓风机房 (8×6) — 南侧
    22: (-20, 0, -18),    # 加药间 (6×5) — 西北侧
    23: (-13, 0, -18),    # 配电间 (5×5)
    24: (-20, 0, -24),    # 实验室 (4×5)
    25: (-28, 0, -24),    # 办公楼 (4×5) — 西北角
    26: (5, 0, 22),       # 维修车间 (6×6) — 南侧
    27: (-5, 0, 22),      # 仓库 (8×6)

    # 厂区设施
    28: (0, 0, 0),        # 场地地基 (6×7) — 中心
    29: (0, 0, 15),       # 主干道 (5×6)
    30: (0, 0, -15),      # 次干道 (1.2×2)
    31: (-8, 0, 5),       # 管道节点A (1.2×2)
    32: (8, 0, -5),       # 管道节点B (1.2×2)
    33: (22, 0, 5),       # 管道节点C (1.2×2)
    34: (38, 0, 0),       # 出水渠道 (3×0.5) — 东侧
    35: (-35, 0, 0),      # 闸门 (3×0.5) — 西侧
    36: (0, 0, 0),        # 厂区围墙 (3×0.5) — 中心
    37: (-28, 0, 15),     # 绿化带 (4×5)
    38: (-22, 0, 20),     # 停车场 (0.8×0.8)
    39: (-35, 0, 12),     # 门卫室 (0.8×0.8) — 西侧入口
}

def fix_obj(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = f.readlines()

    output = []
    current_obj_idx = -1
    obj_count = 0

    for line in lines:
        if line.startswith('o '):
            current_obj_idx = obj_count
            obj_count += 1
            output.append(line)
        elif line.startswith('v '):
            parts = line.strip().split()
            x, y, z = float(parts[1]), float(parts[2]), float(parts[3])
            if current_obj_idx in LAYOUT:
                tx, ty, tz = LAYOUT[current_obj_idx]
                x += tx
                y += ty
                z += tz
            output.append(f'v {x:.8f} {y:.8f} {z:.8f}\n')
        else:
            output.append(line)

    with open(output_path, 'w') as f:
        f.writelines(output)

    # 验证布局
    with open(output_path, 'r') as f:
        lines = f.readlines()

    current_obj = None
    obj_idx = -1
    verts = []
    all_info = []
    for line in lines:
        if line.startswith('o '):
            if current_obj and verts:
                xs = [v[0] for v in verts]
                ys = [v[1] for v in verts]
                zs = [v[2] for v in verts]
                cx, cy, cz = (min(xs)+max(xs))/2, (min(ys)+max(ys))/2, (min(zs)+max(zs))/2
                sx, sy, sz = max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs)
                all_info.append((current_obj, cx, cy, cz, sx, sy, sz))
            current_obj = line.strip().split()[1]
            obj_idx += 1
            verts = []
        elif line.startswith('v '):
            parts = line.strip().split()
            verts.append((float(parts[1]), float(parts[2]), float(parts[3])))
    if current_obj and verts:
        xs = [v[0] for v in verts]
        ys = [v[1] for v in verts]
        zs = [v[2] for v in verts]
        cx, cy, cz = (min(xs)+max(xs))/2, (min(ys)+max(ys))/2, (min(zs)+max(zs))/2
        sx, sy, sz = max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs)
        all_info.append((current_obj, cx, cy, cz, sx, sy, sz))

    # 检查重叠
    overlaps = []
    for i in range(len(all_info)):
        for j in range(i+1, len(all_info)):
            a, b = all_info[i], all_info[j]
            ox = min(a[1]+a[4]/2, b[1]+b[4]/2) - max(a[1]-a[4]/2, b[1]-b[4]/2)
            oz = min(a[3]+a[6]/2, b[3]+b[6]/2) - max(a[3]-a[6]/2, b[3]-b[6]/2)
            oy = min(a[2]+a[5]/2, b[2]+b[5]/2) - max(a[2]-a[5]/2, b[2]-b[5]/2)
            if ox > 0.5 and oz > 0.5 and oy > 0.5:
                overlaps.append((a[0], b[0], ox, oz))

    # 检查超出范围
    oob = [info for info in all_info if abs(info[1]) > 40 or abs(info[3]) > 30]

    print(f'已生成: {output_path} ({obj_count} 对象)')
    print(f'重叠: {len(overlaps)} 对')
    for o in overlaps[:10]:
        print(f'  {o[0]} ↔ {o[1]} (ox={o[2]:.1f}, oz={o[3]:.1f})')
    print(f'超出范围: {len(oob)} 个')
    for o in oob:
        print(f'  {o[0]}: ({o[1]:.1f}, {o[3]:.1f})')

if __name__ == '__main__':
    inp = sys.argv[1] if len(sys.argv) > 1 else 'dsh-test/wastewater-plant-100score.obj.bak'
    outp = sys.argv[2] if len(sys.argv) > 2 else 'dsh-test/wastewater-plant-100score.obj'
    fix_obj(inp, outp)
