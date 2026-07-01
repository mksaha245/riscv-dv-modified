import argparse
import os
import random
import re
import sys
import logging
import yaml
cwd = os.getcwd()
#sys.path.append("/proj/cuzco/users/mksaha/work/mukesh_main/condor-riscv-dv/")
sys.path.append("/proj/cuzco/users/mksaha/work/riscv-dv_replica/condor-riscv-dv/")
cuzco_test_dir = cwd+'/dv/testcase/cz_core/'
regress_dir = cwd+'/dv/testcase/testlists/'
from run import *
               
def parse_args(cwd):
    """Create a command line parser.

    Returns: The created parser.
    """
    # Parse input arguments
    parser = argparse.ArgumentParser()

    parser.add_argument("--target", type=str, default="rv32imc",
                        help="Run the generator with pre-defined targets: \
                            rv32imc, rv32i, rv32imafdc, rv64imc, rv64gc, \
                            rv64imafdc")
    parser.add_argument("-o", "--output", type=str,
                        help="Output directory name", dest="o")
    parser.add_argument("-tl", "--testlist", type=str, default="",
                        help="Regression testlist", dest="testlist")
    parser.add_argument("-tn", "--test", type=str, default="all",
                        help="Test name, 'all' means all tests in the list",
                        dest="test")
    parser.add_argument("-i", "--iterations", type=int, default=1,
                        help="Override the iteration count in the test list",
                        dest="iterations")
    parser.add_argument("-si", "--simulator", type=str, default="vcs",
                        help="Simulator used to run the generator, default VCS",
                        dest="simulator")
    parser.add_argument("--iss", type=str, default="spike",
                        help="RISC-V instruction set simulator: spike,ovpsim,sail")
    parser.add_argument("-v", "--verbose", dest="verbose", action="store_true",
                        default=False,
                        help="Verbose logging")
    parser.add_argument("--co", dest="co", action="store_true", default=False,
                        help="Compile the generator only")
    parser.add_argument("--cov", dest="cov", action="store_true", default=False,
                        help="Enable functional coverage")
    parser.add_argument("--so", dest="so", action="store_true", default=False,
                        help="Simulate the generator only")
    parser.add_argument("--cmp_opts", type=str, default="",
                        help="Compile options for the generator")
    parser.add_argument("--sim_opts", type=str, default="",
                        help="Simulation options for the generator")
    parser.add_argument("--gcc_opts", type=str, default="",
                        help="GCC compile options")
    parser.add_argument("-s", "--steps", type=str, default="all",
                        help="Run steps: gen,gcc_compile,iss_sim,iss_cmp",
                        dest="steps")
    parser.add_argument("--lsf_cmd", type=str, default="",
                        help="LSF command. Run in local sequentially if lsf \
                            command is not specified")
    parser.add_argument("--isa", type=str, default="",
                        help="RISC-V ISA subset")
    parser.add_argument("-m", "--mabi", type=str, default="",
                        help="mabi used for compilation", dest="mabi")
    parser.add_argument("--gen_timeout", type=int, default=360,
                        help="Generator timeout limit in seconds")
    parser.add_argument("--end_signature_addr", type=str, default="0",
                        help="Address that privileged CSR test writes to at EOT")
    parser.add_argument("--iss_opts", type=str, default="",
                        help="Any ISS command line arguments")
    parser.add_argument("--iss_timeout", type=int, default=10,
                        help="ISS sim timeout limit in seconds")
    parser.add_argument("--iss_yaml", type=str, default="",
                        help="ISS setting YAML")
    parser.add_argument("--simulator_yaml", type=str, default="",
                        help="RTL/pyflow simulator setting YAML")
    parser.add_argument("--csr_yaml", type=str, default="",
                        help="CSR description file")
    parser.add_argument("-ct", "--custom_target", type=str, default="",
                        help="Directory name of the custom target")
    parser.add_argument("-cs", "--core_setting_dir", type=str, default="",
                        help="Path for the riscv_core_setting.sv")
    parser.add_argument("-ext", "--user_extension_dir", type=str, default="",
                        help="Path for the user extension directory")
    parser.add_argument("--asm_test", type=str, default="",
                        help="Directed assembly tests")
    parser.add_argument("--c_test", type=str, default="",
                        help="Directed c tests")
    parser.add_argument("--log_suffix", type=str, default="",
                        help="Simulation log name suffix")
    parser.add_argument("--exp", action="store_true", default=False,
                        help="Run generator with experimental features")
    parser.add_argument("-bz", "--batch_size", type=int, default=0,
                        help="Number of tests to generate per run. You can split a big"
                             " job to small batches with this option")
    parser.add_argument("--stop_on_first_error", dest="stop_on_first_error",
                        action="store_true", default=False,
                        help="Stop on detecting first error")
    parser.add_argument("--noclean", action="store_true", default=True,
                        help="Do not clean the output of the previous runs")
    parser.add_argument("--verilog_style_check", action="store_true",
                        default=False,
                        help="Run verilog style check")
    parser.add_argument("-d", "--debug", type=str, default="",
                        help="Generate debug command log file")

    rsg = parser.add_argument_group('Random seeds',
                                    'To control random seeds, use at most one '
                                    'of the --start_seed, --seed or --seed_yaml '
                                    'arguments. Since the latter two only give '
                                    'a single seed for each test, they imply '
                                    '--iterations=1.')

    rsg.add_argument("--start_seed", type=read_seed,
                     help=("Randomization seed to use for first iteration of "
                           "each test. Subsequent iterations use seeds "
                           "counting up from there. Cannot be used with "
                           "--seed or --seed_yaml."))
    rsg.add_argument("--seed", type=read_seed,
                     help=("Randomization seed to use for each test. "
                           "Implies --iterations=1. Cannot be used with "
                           "--start_seed or --seed_yaml."))
    rsg.add_argument("--seed_yaml", type=str,
                     help=("Rerun the generator with the seed specification "
                           "from a prior regression. Implies --iterations=1. "
                           "Cannot be used with --start_seed or --seed."))
    return parser.parse_args()


 
args = parse_args(cwd)
test= args.test
simulator = args.simulator
target = args.target
steps = args.steps
o = args.o
testlist         =args.testlist
iterations       =args.iterations
iss              =args.iss
verbose          =args.verbose
co               =args.co
cov              =args.cov
so               =args.so
cmp_opts         =args.cmp_opts
sim_opts         =args.sim_opts
gcc_opts         =args.gcc_opts
lsf_cmd          =args.lsf_cmd
isa              =args.isa
mabi             =args.mabi
gen_timeout      =args.gen_timeout
end_signature_addr               =args.end_signature_addr
iss_opts         =args.iss_opts
iss_yaml         =args.iss_yaml
simulator_yaml   =args.simulator_yaml
csr_yaml         =args.csr_yaml
custom_target    =args.custom_target
core_setting_dir =args.core_setting_dir
user_extension_dir               =args.user_extension_dir
asm_test         =args.asm_test
c_test           =args.c_test
log_suffix       =args.log_suffix
exp              =args.exp
batch_size       =args.batch_size
stop_on_first_error               =args.stop_on_first_error
noclean          =args.noclean
verilog_style_check               =args.verilog_style_check
debug            =args.debug
#start_seed       =args.start_seed
#seed             =args.seed
#seed_yaml        =args.seed_yaml

#start_seed       =10001010
#seed             =10010043
#seed_yaml        =random.getrandbits(6)
out_dir = test

def write_makefile(test_directory_path,test_name):
    makefile_path = str(test_directory_path)+"/Makefile"
    f = open(makefile_path,"w")
    f.write("TEST={}\nTEST_FILES=$(TEST).s\nexport WS_ROOT ?= $(shell wsroot.py)\ninclude $(WS_ROOT)/dv/software/mk/sw_compile.mk\n".format(test_name))
    f.close()

import os
import shutil

def clean_all(test):
    os.system("rm -rf "+test)
    
def create_directories(test_directory):
    # Get a list of all files in the test directory
    test_directory += "/asm_test/"
    test_files = os.listdir(test_directory)

    # Filter out only the assembly test files
    assembly_test_files = [file for file in test_files if file.endswith('.S')]
    regression_path = str(regress_dir)+test+".tasklist"
    regr_dir = open(str(regression_path),"w")
    for assembly_test_file in assembly_test_files:
	
        # Extract the test name by removing the file extension
        test_name = os.path.splitext(assembly_test_file)[0]
        os.system("rm -rf "+cuzco_test_dir+test_name)

        # Create a directory with the test name if it doesn't exist
        test_directory_path = os.path.join(os.getcwd(), test_name)
        if not os.path.exists(test_directory_path):
            os.makedirs(test_directory_path)
            print(f"Created directory: {test_directory_path}")
	# Create Make file and copy the test
        write_makefile(test_directory_path,test_name)
        #os.system("rm -rf "+cuzco_test_dir+test_name)
        os.system("cp -rf "+str(test_directory)+"/"+assembly_test_file+" "+test_directory_path)
        os.system("cp -rf "+test_name+" "+cuzco_test_dir)
        os.system("rm -rf "+str(test_directory)+"/"+assembly_test_file)
        os.system("rm -rf "+test_name)
        regr_dir.write("sim.cz-multicore.1p+t1h++dis-csr-ecall+l2inc+t1h+main-mem-init0+mmio-mem-init0.xrun.gcc.{}.1 \n".format(test_name))
    regr_dir.close()

cmd = " --test="+test + " --simulator="+simulator + " --target="+target + " --steps="+steps + " --o="+out_dir \
    + " --testlist="+str(testlist) \
    + " --iterations="+str(iterations) \
    + " --iss="+iss \
    + " --cmp_opts="+str(cmp_opts) \
    + " --sim_opts="+str(sim_opts) \
    + " --gcc_opts="+str(gcc_opts) \
    + " --lsf_cmd="+str(lsf_cmd) \
    + " --isa="+str(isa) \
    + " --mabi="+str(mabi) \
    + " --gen_timeout="+str(gen_timeout) \
    + " --end_signature_addr="+str(end_signature_addr) \
    + " --iss_opts="+str(iss_opts) \
    + " --iss_yaml="+str(iss_yaml) \
    + " --simulator_yaml="+str(simulator_yaml) \
    + " --csr_yaml="+str(csr_yaml) \
    + " --custom_target="+str(custom_target) \
    + " --core_setting_dir="+str(core_setting_dir) \
    + " --user_extension_dir="+str(user_extension_dir) \
    + " --asm_test="+str(asm_test) \
    + " --c_test="+str(c_test) \
    + " --log_suffix="+str(log_suffix) \
    + " --batch_size="+str(batch_size) 
#    + " --exp" \
#    + " --stop_on_first_error" \
#    + " --noclean" 
#    + " --verilog_style_check" \
#    + " --debug="+str(debug) 
#    + " --start_seed="+str(start_seed) \
#    + " --seed="+str(seed) \
#    + " --seed_yaml="+str(seed_yaml)
#    + " --co" \
#    + " --cov" \
#    + " --so" \

if verbose:
    cmd_line += " --verbose="+str(verbose) 

clean_all(test)
# concatenate the above string with the command line
#for i in range(0, iter):  # Corrected the range function
seed_s = random.randrange(0, 100)  # Replaced $randrange with random.randrange
cmd_line = "python3 condor-riscv-dv/cuzco_run.py " + cmd #+ " --o="+test+"_"+str(seed_s)
os.system(cmd_line)
print(cmd_line)  # for testing or debugging
create_directories(test)

# cleaning the previous dir with same test
## run above command line

# Replace 'riscv_arithmetic_basic_test' with the actual path to your directory
'''
## creation of makefile for respected test
write_makefile()

## copy the output dir to test directory and run
copy_to_test_dir = "cp -rf "+out_dir+" "+ cuzco_test_dir
os.system(copy_to_test_dir)

run_cmd = "ctm sim.cz-multicore.1p.xrun.gcc."+out_dir+".1"
os.system(run_cmd)
'''
