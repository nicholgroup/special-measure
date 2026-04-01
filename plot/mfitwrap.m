function [ p, chisq , cov] = mfitwrap(data,model,p0,opts,mask)
%mfitwrap fits multiple datasets simultaneously.
% function [ p, chisq, cov ] = mfitwrap(data,model,p0,opts,mask)
% This function fits multiple datasets simultaneously.
% data is a struct array with fields
%  data.x  -- x coordinates
%  data.y  -- y coordinates
%  data.vy -- y variances.  Assumed 1 if not provided.
%  data.rng -- range to fit in x (optional, empty means everything)
% model is a struct array of models to use in the fitting.
%  model.fn  -- fit function, of the form fn(p,x) where p are the parameters
%  model.yfn -- bizarre fit function that transforms y->yfn(p,y,vy).
%  model.pt  -- parameter trafofn.
% p0: initial fit parameters
% opts can include:
%   err - plot error bars
%   anything fitwrap will take.
% default: plfit plinit optimplot
% mask - set to 1 to allow parameter to vary, 0 to hold fixed.
% p is the output parameters
% chisq is the reduced chisq; chi^2/(npts-ndof)
% cov is the covariance of the fit parameters

if ~exist('opts','var')
    opts='plfit plinit optimplot';
end
if ~exist('mask','var')
    mask=ones(size(p0));
end

if ~isempty(strfind(opts,'samefig'))
    figInd=gcf;
else
    figInd=61;
end
o=optimset(optimset('lsqnonlin'),'display','off');
if ~isempty(strfind(opts,'optimplot'))
    o=optimset(o,'PlotFcns',@optimplotresnorm);
end
if ~isempty(strfind(opts,'lm'))
    o=optimset(o,'Algorithm','levenberg-marquardt');
end
if ~isempty(strfind(opts,'fine'))    
    o=optimset(o,'TolX',1e-10,'TolFun',1e-10,'MaxFunEvals',1e5,'MaxIter',1e4);
end
if ~isempty(strfind(opts,'plinit'))
    figure(60);
    set(gcf,'Name','Initial Guess');
    clf;
    lsqfun(data,model,p0,['mustplot samefig' opts],p0,ones(size(p0)));
    
    figure(63);
    clf;
    set(gcf,'Name','Comparison');    
    lsqfun(data,model,p0,['mustplot samefig nofunc' opts],p0,ones(size(p0)));
end

if isempty(strfind(opts,'nofit'))
    
    [pf, chisq, resid, exitflag,output, lambda, jac] = lsqnonlin(@(p) lsqfun(data,model,p,opts,p0,mask), p0(find(mask)),[],[],o);
    covt = pinv(full(jac' * jac));  % Should this be inv not pinv?  singularity implies some fit paramteres don't matter....
    cov=zeros(length(p0),length(p0));
    cov(find(mask),find(mask))=covt;
    p=p0;
    p(find(mask))=pf;
    npts=prod(size([data.x]));
    chisq=chisq/(npts-sum(mask));
else
    p=p0;
    chisq=0;
   
end

%fprintf('chisq=%f, %f points, %d parameters\n',chisq,npts,sum(mask));
if ~isempty(strfind(opts,'plfit')) && isempty(strfind(opts,'nofit'))
    figure(figInd);    
    clf;
    lsqfun(data,model,p,['mustplot samefig' opts],p,ones(size(p)));
    set(gcf,'Name','Best Fit');
    
    figure(63);
    lsqfun(data,model,p0,['mustplot samefig noclear nofunc' opts],p0,ones(size(p0)));
end

end

function err=lsqfun(data, model, pin,opts,p0,mask)
persistent lastplot;
p(find(mask))=pin;
p(find(~mask))=p0(~mask);
err = [];
doplot = ~isempty(strfind(opts,'mustplot'));
if ~isempty(strfind(opts,'plotiter'))
  if isempty(lastplot) | (now > lastplot + 0.5/(24*60*60))
      doplot = 1;
  end
end

if doplot
   lastplot = now;
   if isempty(strfind(opts,'samefig'))
       figure(62);
       set(gcf,'Name','Iteration Display');
       if isempty(strfind(opts,'noclear'));
         clf;
       end
   end
   rows=floor(sqrt(length(data)));
   cols=ceil(length(data)/rows);
end
for i=1:length(data)
    if isfield(model(i),'pt') && ~isempty(model(i).pt)
        pm=model(i).pt(p);
    else
        pm=p;
    end
    if ~isfield(data(i),'vy') || isempty(data(i).vy)
        sy=ones(size(data(i).y));
    else
        sy=data(i).vy;
    end
    if isfield(model(i),'yfn')
        [y,sy]=model(i).yfn(p,data(i).y,sy);
        if any(sy < 0)
            error('Negative variance');            
        end
    else
        y=data(i).y;
    end
    fd=model(i).fn(pm, data(i).x);
    err = [ err (fd-y)./sqrt(sy) ];    
    if any(imag(err) ~= 0)
        error('Imaginary error');
    end
    if doplot
      subplot(rows,cols,i);      
      s=sqrt(sy);
%      plot(data(i).x,y,'rx',data(i).x+s,y,'r.',data(i).x-s,y,'r.',data(i).x,fd,'b-');
      if ~isempty(strfind(opts,'err')) && 1
        if ~isempty(strfind(opts,'green'))          
            errorbar(data(i).x,y,sqrt(sy),'g');
        else
            errorbar(data(i).x,y,sqrt(sy),'r');
        end
      end
      hold on;
        if ~isempty(strfind(opts,'green'))
          plot(data(i).x,y,'kx-');
        else
          plot(data(i).x,y,'kx-');
        end
      
      hold on;
      if any(imag(fd) ~= 0)
          error('Imaginary fit');
      end
      if isempty(strfind(opts,'nofunc'))
        plot(data(i).x,fd,'b-');
      end
    end 
end
if doplot
    drawnow;
end
err=err';
if ~isempty(strfind(opts,'robust'))
  err = err ./ sqrt(abs(err));  % robust fit.
end
end

