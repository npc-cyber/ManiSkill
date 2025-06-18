# diffusion_policy训练过程

扩散模型的核心思想是学习逆转噪声添加过程

训练过程是前向过程 是加噪声的：
逐步添加noise到action
根据obs和noise_action(state?)预测noise
最小化noise与pred_noise的均方误差

使用过程是反向过程 是去噪的：
初始化 init_noise
根据cur_noise与obs预测当前noise
添加noise到 cur_noise
最终的cur_noise就是最终的action   


# 模型的时序

这个地方显示了模型的时序
所以是输入是 prev_frame和cur_frame
|o|o|                             observations: 2
| |a|a|a|a|a|a|a|a|               actions executed: 8
|p|p|p|p|p|p|p|p|p|p|p|p|p|p|p|p| actions predicted: 16

# 模型的处理

从这个可以发现
视觉特征是通过卷积神经网络 
转换成和robot_state一样的状态了 (B, obs_horizon, D+obs_state_dim)
def encode_obs(self, obs_seq, eval_mode):

# 数据放置地址
ls demos/
PickCube-v1