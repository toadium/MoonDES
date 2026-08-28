#!/usr/bin/env python3
"""
修复 OBJ 文件 — 给每个构筑物赋予正确的世界坐标位置

根据设计规格书中的厂区总平面布置图:
- 水流方向: 从左(西, X负)到右(东, X正)
- 北侧(Z负): 办公楼/实验室/配电间/加药间 + 污泥处理区
- 中央: 主处理构筑物沿水流方向排列
- 南侧(Z正): 辅助建筑(仓库/维修/鼓风机房/门卫)
- 厂区尺寸: 80m(X) × 60m(Z)
"""

import sys

# 40 个构筑物的世界坐标偏移 (tx, ty, tz)
# 基于设计规格书的厂区总平面布置
LAYOUT = {
    0:  (-35, 0, 0),      # 进水检查井 — 最西侧
    1:  (-30, 0, 0),      # 粗格栅间
    2:  (-25, 0, 0),      # 细格栅间
    3:  (-20, 0, 0),      # 提升泵房
    4:  (-14, 0, 0),      # 曝气沉砂池
    5:  (-8, 0, 0),       # 初沉池
    6:  (-2, 0, -6),      # 缺氧池 — AAO区, 北侧
    7:  (3, 0, -6),       # 厌氧池
    8:  (8, 0, -6),       # 好氧池
    9:  (14, 0, -8),      # 接触区
    10: (14, 0, 8),       # 二沉池 — 南侧
    11: (8, 0, 8),        # 曝气器
    12: (-2, 0, 8),       # 搅拌机
    13: (20, 0, -6),      # 深床滤池
    14: (25, 0, 0),       # 紫外消毒渠
    15: (30, 0, -6),      # 清水池
    16: (35, 0, 0),       # 出水计量槽 — 最东侧
    17: (25, 0, -18),     # 污泥浓缩池 — 东北角
    18: (32, 0, -18),     # 污泥储池
    19: (25, 0, -24),     # 脱水机房
    20: (32, 0, -24),     # 污泥干化间
    21: (10, 0, 22),      # 鼓风机房 — 南侧
    22: (-22, 0, -18),    # 加药间 — 西北侧
    23: (-16, 0, -18),    # 配电间
    24: (-22, 0, -24),    # 实验室
    25: (-30, 0, -24),    # 办公楼 — 西北角
    26: (-5, 0, 22),      # 维修车间 — 南侧
    27: (-15, 0, 22),     # 仓库
    28: (0, 0, 0),        # 场地地基 — 中心(大平面,保持不变)
    29: (0, 0, 12),       # 主干道 — 中部南北向
    30: (0, 0, -12),      # 次干道
    31: (-10, 0, 5),      # 管道节点A
    32: (5, 0, -10),      # 管道节点B
    33: (20, 0, 5),       # 管道节点C
    34: (35, 0, 0),       # 出水渠道 — 东侧
    35: (-35, 0, 0),      # 闸门 — 西侧(进水)
    36: (0, 0, 0),        # 厂区围墙 — 外围(保持不变)
    37: (-30, 0, 15),     # 绿化带
    38: (-25, 0, 18),     # 停车场 — 西南侧
    39: (-35, 0, 10),     # 门卫室 — 西侧入口
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

            # 应用偏移
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

    print(f'已生成: {output_path}')
    print(f'对象数: {obj_count}')

    # 验证
    with open(output_path, 'r') as f:
        lines = f.readlines()

    current_obj = None
    obj_idx = -1
    verts = []
    for line in lines:
        if line.startswith('o '):
            if current_obj and verts:
                xs = [v[0] for v in verts]
                ys = [v[1] for v in verts]
                zs = [v[2] for v in verts]
                cx, cy, cz = (min(xs)+max(xs))/2, (min(ys)+max(ys))/2, (min(zs)+max(zs))/2
                print(f'  {current_obj}: center=({cx:.1f}, {cy:.1f}, {cz:.1f})')
            current_obj = line.strip().split()[1]
            obj_idx += 1
            verts = []
        elif line.startswith('v '):
            parts = line.strip().split()
            verts.append((float(parts[1]), float(parts[2]), float(parts[3])))

    # Last object
    if current_obj and verts:
        xs = [v[0] for v in verts]
        ys = [v[1] for v in verts]
        zs = [v[2] for v in verts]
        cx, cy, cz = (min(xs)+max(xs))/2, (min(ys)+max(ys))/2, (min(zs)+max(zs))/2
        print(f'  {current_obj}: center=({cx:.1f}, {cy:.1f}, {cz:.1f})')

if __name__ == '__main__':
    inp = sys.argv[1] if len(sys.argv) > 1 else 'dsh-test/wastewater-plant-100score.obj'
    outp = sys.argv[2] if len(sys.argv) > 2 else 'dsh-test/wastewater-plant-100score.obj'
    fix_obj(inp, outp)
