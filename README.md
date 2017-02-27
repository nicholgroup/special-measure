# special-measure
Nichol Group Special Measure 

Forked from Yacoby Lab Special Measure

# Installation
1. Download and install git.
2. First clone the repository.  Open the git command line. Use the "cd" command to navigate to the place you want to download the repo. Then type 
`git clone https://github.com/nicholgroup/special-measure.git`
3. You need an instrument control toolbox. (i.e., the National Instruments or Tektronix drivers). This will typically be achieved in you install NI 488.2, for example.
4. Open matlab, and add the repo directory with all subfolders to your path.
5. Make sure the sm and sm/channels directories are in the path.
6. Make smdata accessible from the workspace by typing `global smdata;` This is necessary only once per Matlab session, or after a `clear global` command.

# Basic Github 
Github allows us to work on the software as a team and keep track of changes made. First, open the git shell. To tell the git shell who you are, type 

`git config --global user.name` or `git config --global  user.email`

where you should replace `user.name` or `user.email` with your github name or email address.

If you want to make sure your local clone is up to date, pull in changes from the repository. Type

`git pull`

Suppose you made some changes and want to commit these changes to the repo. To stage all changes, type

`git add -A`

To commit all of these changes, type

`git commit -m "message describing changes"`

Finally, to upload your changes to the server, type

`git push origin master`

Ordinarily, if you are making big changes, you should work in a separate branch, which can later be merged with the master branch in a pull request. In this case, before you commit, you should make and commit to a new branch using `git checkout`. That way, you can safely make changes without affecting the master. Once you are happy that all changes do not break any code, you can open a pull request.

If working on a shared computer, you can remove your profile from the git shell by typing

`git config --global --unset user.name` or `git config --global --unset user.email`

See http://dont-be-afraid-to-commit.readthedocs.io/en/latest/git/commandlinegit.html, and many other github tutorials for more details.

# Contributing

We use the matlab style guide, found here: https://www.mathworks.com/matlabcentral/fileexchange/46056-matlab-style-guidelines-2-0?requestedDomain=www.mathworks.com

All changes should be documented.
