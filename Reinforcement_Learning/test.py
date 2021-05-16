from evaluation import TEST_EVAL
from actor_network import TEST_POLICY
from environment.env_filter import ENV
from numpngw import write_apng
import gym

'''         1. Test configuration       '''

MODEL_PATH = "./drive/My Drive/RL/results/checkpoint/pybullet_cartpole-v0"
STATE_INPUT_NAME = 'state_input:0'
ACTION_NAME = 'actor/FC3/dense/Tanh:0'
NUM_EVAL = 10


'''         2. Restore policy           '''

actor = TEST_POLICY(model_path=MODEL_PATH,
                    state_input_name=STATE_INPUT_NAME,
                    action_name=ACTION_NAME)


'''         3. Evaluation               '''

env = ENV(gym.make('pybullet_cartpole-v0'))
avg_eval, images = TEST_EVAL(env, actor, NUM_EVAL)