import subprocess


def run_cmd(cmd):
    """Run a command in a subprocess sub-shell

    Arguments:
        cmd {list of strings} -- Bash command to be run

    Returns:
        dict -- A dictionary containing:
                * return code
                * output
                * error message
    """
    result = {}

    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output = proc.communicate()

        result["returncode"] = proc.returncode
        result["output"] = output[0].decode(encoding="utf-8").strip("\n")
        result["err_msg"] = output[1].decode(encoding="utf-8").strip("\n")
    except FileNotFoundError:
        result["returncode"] = 1
        result["ouptut"] = ""
        result["err_msg"] = "FileNotFoundError"

    return result


def run_pipe_cmd(cmds):
    """Pipe together a set of bash commands

    Arguments:
        cmds {a list of lists of strings} -- The commands to be piped together

    Returns:
        dict -- A dictionary containing:
                * return code
                * output
                * error message
    """
    N = len(cmds)  # Number of commands to pipe together
    procs = []  # List to track processes in
    result = {}  # Dictionary to store outputs in

    try:
        for i in range(N):
            if i == 0:
                proc = subprocess.Popen(
                    cmds[i], stdout=subprocess.PIPE, stderr=subprocess.PIPE
                )
                procs.append(proc)
            else:
                proc = subprocess.Popen(
                    cmds[i],
                    stdin=procs[i - 1].stdout,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                procs[i - 1].stdout.close()
                procs.append(proc)

        output = procs[-1].communicate()

        result["returncode"] = procs[-1].returncode
        result["output"] = output[0].decode(encoding="utf-8").strip("\n")
        result["err_msg"] = output[1].decode(encoding="utf-8").strip("\n")

    except FileNotFoundError:
        result["returncode"] = 1
        result["output"] = ""
        result["err_msg"] = "FileNotFoundError"

    return result
