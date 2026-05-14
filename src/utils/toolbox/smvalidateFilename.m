function cleanName = smvalidateFilename(name)
% smvalidateFilename  Validate and sanitize a scan filename.
%   cleanName = smvalidateFilename(name) checks that NAME follows the
%   naming rules for scan data files and throws an error if it contains
%   forbidden characters.
%
%   Rules
%   -----
%   1. No periods (.)        — causes fileparts / extension confusion
%   2. No ampersand (&)      — shell meta-character
%   3. No asterisk (*)       — wildcard / glob conflict
%   4. No question mark (?)  — wildcard / glob conflict
%   5. No spaces             — path quoting issues
%   6. No quotes (' or ")    — shell quoting issues
%   7. No angle brackets     — redirection operators
%   8. No pipe (|)           — shell pipe
%   9. No colon (:)          — drive-letter separator on Windows
%  10. No semicolon (;)      — command separator
%  11. No hash (#)           — comment character in many contexts
%  12. No percent (%)        — MATLAB special character in sprintf
%  13. No curly braces       — MATLAB cell indexing
%  14. No square brackets    — MATLAB array syntax
%  15. No parentheses        — MATLAB function calls
%  16. No exclamation (!)    — MATLAB system command prefix
%  17. No at-sign (@)        — MATLAB class folder prefix
%  18. No comma (,)          — MATLAB separator
%  19. No plus (+)           — MATLAB package folder prefix
%  20. No equals (=)         — assignment operator
%  21. No backtick (`)       — shell expansion
%  22. No tilde (~)          — home directory expansion
%  23. No caret (^)          — regex / shell special
%  24. No dollar ($)         — variable expansion
%  25. No backslash (\)      — escape character (paths handled separately)
%
%   Allowed: letters, digits, underscore (_), and hyphen (-).
%
%   The check is applied to the bare name only — any directory prefix and
%   the .mat extension are stripped before validation.

% Accept both char vectors and string scalars
if isstring(name)
    name = char(name);
end

if isempty(name)
    cleanName = name;
    return
end

% Separate directory, bare name, and extension
[fpath, fname, ext] = fileparts(name);

% If the extension is .mat, work with fname only.
% Otherwise the "extension" is part of the name (e.g. 'scan.v2' ->
% fname='scan', ext='.v2'), so recombine.
if strcmpi(ext, '.mat')
    bareName = fname;
else
    bareName = [fname ext];  % keep everything after last filesep
end

% --- also handle periods *within* bareName that fileparts could not see
% (fileparts only splits on the last dot) ---
% e.g. 'sm_scan.v2.1' -> fname='sm_scan.v2', ext='.1'

% Define the allowed pattern: letters, digits, underscore, hyphen
forbidden = regexp(bareName, '[^A-Za-z0-9_\-]', 'match');

if ~isempty(forbidden)
    unique_bad = unique(forbidden);
    charList = strjoin(unique_bad, '  ');
    error('smvalidateFilename:badChars', ...
        ['Filename "%s" contains forbidden character(s):  %s\n' ...
         'Allowed characters: letters, digits, underscore (_), hyphen (-).\n' ...
         'Please rename before running the scan.'], ...
        bareName, charList);
end

cleanName = name;
end
