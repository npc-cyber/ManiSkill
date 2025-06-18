#!/bin/bash

# 设置默认控制模式
CONTROL_MODE="pd_ee_delta_pos"

# 检查是否传入参数
if [ $# -eq 0 ]; then
    echo "请传入参数选择要执行的命令："
    echo " 1: 保存演示视频(单进程)"
    echo " 2: 转换控制模式(单进程)"
    echo " 3: 转换到CUDA后端并生成rgb观测(单进程)"
    echo " 4: 训练state观测模型(单进程)(不推荐无用模型)"
    echo " 5: 训练rgb观测模型(前台单进程)"
    echo " 6: 训练rgb观测模型(后台单进程)"
    echo " 7: 训练rgb观测模型(多卡分布式训练)"
    echo " 8: 测试模型(单进程)"
    echo ""
    echo "当前控制模式: $CONTROL_MODE"
    exit 1
fi

# 根据传入的参数执行不同的命令
case $1 in
    1)
        echo "执行命令1: 保存演示视频(单进程)"
        python -m mani_skill.trajectory.replay_trajectory \
            --traj-path ../../../demos/PickCube-v1/motionplanning/trajectory.h5 \
            --save-video
        ;;
    
    2)
        echo "执行命令2: 转换控制模式为state(单进程)"
        python -m mani_skill.trajectory.replay_trajectory \
            --traj-path ../../../demos/PickCube-v1/motionplanning/trajectory.h5 \
            -c $CONTROL_MODE -o state \
            --save-traj
        ;;
    
    3)
        echo "执行命令3: 转换到CUDA后端并生成rgb观测(单进程)"
        python -m mani_skill.trajectory.replay_trajectory \
            --traj-path ../../../demos/PickCube-v1/motionplanning/trajectory.state.${CONTROL_MODE}.physx_cpu.h5 \
            --use-first-env-state -b "physx_cuda" \
            -c $CONTROL_MODE -o rgb \
            --save-traj
        ;;
    
    4)
        echo "执行命令4: 训练state观测模型(单进程)"
        python train.py --env-id PickCube-v1 \
            --demo-path ../../../demos/PickCube-v1/motionplanning/trajectory.state.${CONTROL_MODE}.physx_cuda.h5 \
            --control-mode $CONTROL_MODE --sim-backend "physx_cuda" --num-demos 100 --max_episode_steps 100 \
            --total_iters 30000 \
            --exp-name diffusion_policy-${CONTROL_MODE}-PickCube-v1-state-100_motionplanning_demos-1 \
            --track
        ;;
    
    5)
        echo "执行命令5: 训练rgb观测模型(前台单进程)"
        
        echo "延时结束，开始执行训练任务..."
        python train_rgbd.py --env-id PickCube-v1 \
            --demo-path ../../../demos/PickCube-v1/motionplanning/trajectory.rgb.${CONTROL_MODE}.physx_cuda.h5 \
            --control-mode $CONTROL_MODE --sim-backend "physx_cuda" --num-demos 100 --max_episode_steps 100 \
            --total_iters 3 --obs-mode "rgb" \
            --exp-name diffusion_policy-${CONTROL_MODE}-PickCube-v1-rgb-100_motionplanning_demos-1 \
            --batch_size 64 --gpu_id 1
        ;;
    
    6)
        echo "执行命令6: 训练rgb观测模型(后台单进程)"

        nohup python train_rgbd.py --env-id PickCube-v1 \
            --demo-path ../../../demos/PickCube-v1/motionplanning/trajectory.rgb.${CONTROL_MODE}.physx_cuda.h5 \
            --control-mode $CONTROL_MODE --sim-backend "physx_cuda" --num-demos 100 --max_episode_steps 100 \
            --total_iters 120000 --obs-mode "rgb" \
            --exp-name diffusion_policy-${CONTROL_MODE}-PickCube-v1-rgb-100_motionplanning_demos-1 \
            --batch_size 64 --save_freq 10000 > train_rgbd_${CONTROL_MODE}.log 2>&1 &
        
        echo "日志将输出到: train_rgbd_${CONTROL_MODE}.log"
        echo "使用以下命令查看实时日志:"
        echo "  tail -f train_rgbd_${CONTROL_MODE}.log"
        ;;
    
    7)
        echo "执行命令7: 训练rgb观测模型(多卡分布式训练)"
        echo "使用 GPU 数量: 2 (通过 --nproc_per_node=2 设置)"
        echo "训练脚本: train_rgbd_dist.py"
        echo "控制模式: $CONTROL_MODE"
        
        torchrun --nproc_per_node=2 --standalone train_rgbd_dist.py \
            --env-id PickCube-v1 \
            --demo-path ../../../demos/PickCube-v1/motionplanning/trajectory.rgb.${CONTROL_MODE}.physx_cuda.h5 \
            --control-mode $CONTROL_MODE \
            --sim-backend "physx_cuda" \
            --num-demos 100 \
            --max_episode_steps 100 \
            --total_iters 300 \
            --obs-mode "rgb" \
            --exp-name diffusion_policy-${CONTROL_MODE}-PickCube-v1-rgb-100_motionplanning_demos-1 \
            --batch_size 1024 \
            --save_freq 100 \
        ;;
    
    8)
        echo "执行命令8: 测试模型(单进程)"
        python train_rgbd.py --env-id PickCube-v1 \
            --demo-path ../../../demos/PickCube-v1/motionplanning/trajectory.rgb.${CONTROL_MODE}.physx_cuda.h5 \
            --control-mode $CONTROL_MODE --sim-backend "physx_cuda" --num-demos 10 --max_episode_steps 100 \
            --total_iters 30000 --obs-mode "rgb" \
            --exp-name diffusion_policy-${CONTROL_MODE}-PickCube-v1-rgb-100_motionplanning_demos-1 \
            --batch_size 256 --test_mode
        ;;
    
    *)
        echo "错误：无效参数 '$1'"
        echo "可用参数: 1, 2, 3, 4, 5, 6, 7, 8"
        exit 1
        ;;
esac