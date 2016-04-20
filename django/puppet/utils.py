import subprocess

def run_command(command, cwd='/tmp'):
    p = subprocess.Popen(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    return p.communicate()
