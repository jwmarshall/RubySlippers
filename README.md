# RubySlippers

*There's no place like /home*

RubySlippers is a home directory management and teleportation tool with a git backend. The idea is that you should be able to take your environment with you everywhere you go. This includes your files, dot files, directories of scripts, anything you would want to carry across multiple servers.

If you work on lots of servers and constantly find yourself without your favourite .bashrc or .vimrc then RubySlippers can help solve that problem.

RubySlippers is still quite a young project, and there could be bugs. If you like the idea and want to contribute to RubySlippers please fork and send me your pull requests. 

## Examples

`./RubySlippers.rb --help`

    $ ./RubySlippers.rb
    Tasks:  
      RubySlippers.rb carry FILE [TARGET]  # Carry a file or directory in your repository  
      RubySlippers.rb commit               # Commit any modified files in your repository  
      RubySlippers.rb drop FILE            # Drop (delete) a file or directory from your repository
      RubySlippers.rb equip FILE TARGET    # Symlink file from repository into your home directory
      RubySlippers.rb help [TASK]          # Describe available tasks or one specific task
      RubySlippers.rb init GIT_URI         # Initialize and setup your home repository
      RubySlippers.rb pull                 # Forced pull
      RubySlippers.rb push                 # Forced push
      RubySlippers.rb unequip FILE         # Unequip a file from your repository

**Carry a file with you**

`RubySlippers carry ~/.bashrc`

**Carry a file with optional target location** (target location is always prefixed with you repository root)

`RubySlippers carry ~/.bashrc dotfiles/bashrc`

**Carry an entire directory of files**

`RubySlippers carry ~/scripts`

**Drop (delete) a file from your repository**

`RubySlippers drop .bashrc`

**Equip a file** 

`RubySlippers equip dotfiles/bashrc ~/.bashrc`

**Unequip a file**

`RubySlippers ~/.bashrc`


## To Do

- **Persistant equips** - Ensure your equipped files are present on all hosts (equips are maintained with symlinks)
- **Per-host equips/uneqiups** - Deal with host specific equips and unequips
- **Submodules** - Allow users to keep submodules in their repositories (your favourite scripts/dotfiles from github perhaps)
- **Merge Conflicts** - Dealing with conflicts
- **Hook login/logout** - Do a pull at login, run through file persistance, warn of uncommitted changes at logout (probably background tasks, or potentially a daemon process)

