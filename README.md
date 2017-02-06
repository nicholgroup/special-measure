# special-measure
Nichol Group Special Measure 

Forked from Yacoby Lab Special Measure

# Installation
1. Download and install git.
2. First clone the repository.  Open the git command line. Use the "cd" command to navigate to the place you want to download the repo. Then type 
`git clone https://github.com/nicholgroup/special-measure.git`
3. Open matlab, and add the repo directory with all subfolders to your path.

# Basic Github 
Github allows us to work on the software as a team and keep track of changes made. To commit changes to the repo, open the git shell. To stage all changes, type

`git add -A`

To commit all of these changes, type

`git commit -m "message describing changes"`

Finally, to upload your changes to the server, type

`git push origin master`

Ordinarily, if you are making big changes, you should work in a separate branch, which can later be merged with the master branch in a pull request. In this case, before you commit, you should make and commit to a new branch using `git checkout`. That way, you can safely make changes without affecting the master. Once you are happy that all changes do not break any code, you can open a pull request.

See http://dont-be-afraid-to-commit.readthedocs.io/en/latest/git/commandlinegit.html, and many other github tutorials for more details.

# Contributing

We use the matlab style guide, found here: https://www.mathworks.com/matlabcentral/fileexchange/46056-matlab-style-guidelines-2-0?requestedDomain=www.mathworks.com

All changes should be documented.
