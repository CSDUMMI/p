#!/usr/bin/env python3

import os
from subprocess import call

from p import find_available_commands, alias_and_resolve, auto_detect_project_type, read_cfg

# Increased for each command executed through p
RECURSION_DEPTH_ENVIRONMENT_VARIABLE = '_P_RECURSION_DEPTH'

# main function, execute and exit, thus executing the upper level command
def main(argv):
    # Get file name
    _, my_name = os.path.split(argv[0])
    # Get command name of this programm
    cmd_name, _ = os.path.splitext(my_name)

    # All commands in p
    available_commands = find_available_commands()

    # Load configurations for this command
    cfg = read_cfg(cmd_name=cmd_name)

    # p needs to know the project type to work rigth.
    if 'project_type' not in cfg:
        detected_project_type = auto_detect_project_type(cmd_name=cmd_name, available_commands=available_commands)
        if detected_project_type:
            cfg['project_type'] = detected_project_type

    recursion_depth = int(os.environ.get(RECURSION_DEPTH_ENVIRONMENT_VARIABLE, '0'))

    # Don't execute too many commands
    if recursion_depth > 50:
        raise RecursionError("Too many commands executed in p")

    command = alias_and_resolve(
        cmd_name=cmd_name, # Name of the command
        cmd=(cmd_name, ) + tuple(argv[1:]), # Command = Command Name and Arguments to command
        available_commands=available_commands,
        cfg=cfg,
    )

    if command is None:
        project_type = cfg['project_type'] if 'project_type' in cfg else "Unknown project type"
        avaible_cmds = '\n'.join([cmd for cmd in sorted(avaible_commands) if not cmd.startswith(f'{cmd_name}-projecttype-')])
        raise ValueError(
            """
Unknown command.
Project type: {}
Avaible Commands:
{}
            """.format(project_type,avaible_cmds))

    else:
        return call(
            command,
            shell=True,
            stdin=sys.stdin,
            stdout=sys.stdout,
            stderr=sys.stderr,
            env={
                **os.environ,
                RECURSION_DEPTH_ENVIRONMENT_VARIABLE: str(recursion_depth + 1),
            },
        )


if __name__ == '__main__':
    import sys
    exit(main(sys.argv))
