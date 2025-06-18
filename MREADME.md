# 环境安装问题

pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade mani_skill

# 数据处理问题

下载的数据只有轨迹 需要转换成我们需要的数据格式

python -m mani_skill.trajectory.replay_trajectory \
  --traj-path ../../..//demos/PickCube-v1/motionplanning/trajectory.h5 \
  --save-traj --target-control-mode pd_joint_delta_pos \
  --obs-mode none --num-procs 10

  