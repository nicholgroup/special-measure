function val = smctest(ic, val, rate)

global smdata;
global tunedata;

switch ic(2) % channels
    case {1,2,3} % e.g., count, count2, count3
        switch ic(3)
            case 0 %get
                val = smdata.inst(ic(1)).data.val(ic(:, 2));
            case 1 %set
                smdata.inst(ic(1)).data.val(ic(:, 2)) = val;
                if nargin >= 3
                    %fprintf('%d %f %f\n',ic(:, 2), val, rate);
                else
                    %fprintf('%d %f\n',ic(:, 2), val);
                end
            case 3
            case 4
            case 5
            otherwise
                warning('Operation not supported');
        end

end

end