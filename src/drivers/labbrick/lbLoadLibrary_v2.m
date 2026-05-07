function ret=lbLoadLibrary_v2()
% Load the lab brick driver library.  Return true on success.
%this version uses the vaunix api
ret = true;
if ~libisloaded('vaunixapi')
    
    p=strrep(which('smcLabBrick'),'smcLabBrick.m','labbrick\vaunix\') ;
    
    libname='vnx_fsynth';
    hname='vnx_LSG_api';
    
    loadlibrary([p libname '.dll'],[p hname '.h'],'alias','vaunixapi');
    
    
    if ~libisloaded('vaunixapi')
        ret=false;
    end
end