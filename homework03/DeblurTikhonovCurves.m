%  
%  1d image deblurring inverse problem with Dirichlet boundary conditions.
%
clear all, close all
n = 80; %%%input(' No. of grid points = ');
h = 1/n;
t = [h/2:h:1-h/2]';
sig = .05; %%%input(' Kernel width sigma = ');
kernel = (1/sqrt(pi)/sig) * exp(-(t-h/2).^2/sig^2);
A = toeplitz(kernel)*h;

% Set up true solution x_true and data b = A*x_true + error.
x_true = .75*(.1<t&t<.25) + .25*(.3<t&t<.32) + (.5<t&t<1).*sin(2*pi*t).^4;
x_true = x_true/norm(x_true);
Ax = A*x_true;
err_lev = 2; %%%input(' Percent error in data = ');
sigma = err_lev/100 * norm(Ax) / sqrt(n);
rng(0) % Use randn('seed',0) for old version of MATLAB
eta =  sigma * randn(n,1);
b = Ax + eta;
figure(1), 
  plot(t,x_true,'k',t,b,'ko')
  %legend('true image','blurred, noisy data','Location','NorthWest')

% Compute Tikhonov solution
[U,S,V] = svd(A);
dS = diag(S); dS2 = dS.^2; 
Utb = U'*b;
RelEr_fn = @(a) norm(V*((dS./(dS.^2+a)).*(U'*b))-x_true)/norm(x_true);
MSE_fn = @(a) sigma^2*sum((dS./(dS.^2+a)).^2)+sum((a./(dS.^2+a)).^2.*(V'*x_true).^2);
UPRE_fn = @(a) sum((a^2*Utb.^2)./(dS2+a).^2)+2*sigma^2*sum(dS2./(dS2+a));
GCV_fn = @(a) sum((a^2*Utb.^2)./(dS2+a).^2)/(n-sum(dS2./(dS2+a)))^2;
DP_fn = @(a) (sum((a^2*Utb.^2)./(dS2+a).^2)-n*sigma^2)^2;
Lcurve_fn = @(alpha) - curvatureLcurve(alpha,A,U,S,V,b);

% Now compute the various error curves and corresponding optimal
% regularization parameter for each curve.
agrid     = logspace(-5,0);
RelEr_vec = zeros(size(agrid));
MSE_vec   = zeros(size(agrid));
for i=1:length(agrid)
    RelEr_vec(i) = RelEr_fn(agrid(i));
    MSE_vec(i)   = MSE_fn(agrid(i));
end
iRelEr = find(RelEr_vec==min(RelEr_vec));
iMSE   = find(MSE_vec==min(MSE_vec));
figure(2)
  loglog(agrid,RelEr_vec,'k',agrid,MSE_vec,'r--',...
  agrid,arrayfun( UPRE_fn  ,agrid ),'b:',...
  agrid,arrayfun( GCV_fn   ,agrid ),'c-.',...
  agrid,arrayfun( DP_fn	   ,agrid ),'m-.s',...
  agrid,arrayfun( @(a) exp(Lcurve_fn(a)),agrid ),'y-.d'...
  )
  legend('relative error', 'MSE', 'UPRE', 'GCV', 'DP', 'L-curve', 'Location', 'Southeast')
  hold on
  loglog(agrid(iRelEr),RelEr_vec(iRelEr),'k*', agrid(iMSE),MSE_vec(iMSE),'r*',...
    fminbnd( UPRE_fn, 1e-4, 1e-1), UPRE_fn(fminbnd( UPRE_fn, 1e-4, 1e-1)),'b*',...
    fminbnd( GCV_fn , 1e-4, 1e-1), GCV_fn (fminbnd( GCV_fn , 1e-4, 1e-1)),'c*',...
    fminbnd( DP_fn  , 1e-4, 1e-1), DP_fn  (fminbnd( DP_fn  , 1e-4, 1e-1)),'m*',...
    fminbnd( Lcurve_fn,1e-4, 1e-1),exp(Lcurve_fn(fminbnd( Lcurve_fn,1e-4, 1e-1))),'y*'... 
  ) 
  hold off
  title('Parameter Selection Curves for Debluring Example')
  saveTightFigure(figure(2),'all_curves.pdf')
figure(3)
  plot(t,x_true,'k--',t,V*((dS./(dS.^2+agrid(iRelEr))).*(U'*b)),'k',t,V*((dS./(dS.^2+agrid(iMSE))).*(U'*b)),'r--')
  legend('true image','min relative error soln','min MSE soln')

sprintf( 'relative error = %.3e \n MSE = %.3e \n UPRE = %.3e \n GCV = %.3e \n DP = %.3e \n L-curve = %.3e', ...
fminbnd( RelEr_fn,1e-4, 1e-1),...
fminbnd( MSE_fn, 1e-4, 1e-1),...
fminbnd( UPRE_fn, 1e-4, 1e-1),...
fminbnd( GCV_fn , 1e-4, 1e-1),...
fminbnd( DP_fn  , 1e-4, 1e-1),...
fminbnd( Lcurve_fn,1e-4, 1e-1))



