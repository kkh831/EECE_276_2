import tensorflow as tf
from environment.env_filter import ENV
from TD3 import TD3_TRAINER
import gym, os
import pandas as pd

flags = tf.flags
FLAGS = flags.FLAGS

''' ENVIRONMENT '''
# Set environment here
flags.DEFINE_string("env_name", "pybullet_cartpole-v0", "Environment name")
env = ENV(gym.make(FLAGS.env_name))

''' ALGORITHM '''
flags.DEFINE_string("algorithm", "TD3", "Option: [TD3]")
flags.DEFINE_integer("random_seed", 0, "Random seed for reproducing results")

''' MONITORING AND RENDERING '''
flags.DEFINE_boolean("monitoring", True, "If True, the results of evaluation are saved as a csv file")
flags.DEFINE_string("file_name", "CoRL", "File name for saving the results of evaluation and parameters")
flags.DEFINE_boolean("rendering", True, "If True, rendering is executed at the last of every evaluation stages")

''' META PARAMETERS '''
flags.DEFINE_integer("max_interaction", 1000000, "Maximum value of training iterations")
flags.DEFINE_integer("max_step", env.max_step(), "Cutoff for continuous task. Default value is the value defined in the environment")
flags.DEFINE_integer("random_step", 1000, "The number of initial exploration steps")
flags.DEFINE_integer("eval_period", 5000, "Policy is frequently evaluated after experiencing this number of episodes")
flags.DEFINE_integer("num_eval", 10, "Policy is evaluated by testing this number of episodes and averaging the total reward")
flags.DEFINE_float("gamma", 0.99, "Discounting factor")
flags.DEFINE_float("reward_scale", 1.0, "Scaling reward by this factor")

''' DATA HANDLING '''
flags.DEFINE_integer("buffer_size", 1000000, "Buffer size")
flags.DEFINE_integer("batch_size", 100, "Batch size for each updates")
flags.DEFINE_integer("replay_start_size", 100, "Buffer size for starting updates")

''' UPDATE '''
flags.DEFINE_float("target_pol_alpha", 0.995, "Exponential moving decay rate for target policy update")
flags.DEFINE_float("target_val_alpha", 0.995, "Exponential moving decay rate for target critic update")
flags.DEFINE_integer("num_update", 1, "The number of updating networks per iteration")
flags.DEFINE_float("pol_lr", 1e-3, "Learning rate for policy network")
flags.DEFINE_float("val_lr", 1e-3, "Learning rate for Q network")

if __name__ == "__main__":
    root = "./drive/My Drive/RL/results/"
    if FLAGS.monitoring == True:
        file = pd.DataFrame(columns=["Episode", "Step", "Max", "Min", "Average"])
        if not os.path.isdir(root): os.mkdir(root)
        file.to_csv(root+"evaluation.csv", index=False)

    TRAINING_AGENT = TD3_TRAINER(env, FLAGS)
    TRAINING_AGENT.execution()