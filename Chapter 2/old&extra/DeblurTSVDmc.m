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
nsamps = 1000;
eta =  sigma * randn(n,nsamps);
b = repmat(Ax,1,nsamps) + eta;

% Compute TSVD solution
[U,S,V] = svd(A);
Utb = U'*b;
dS = diag(S); 
param_choice = input(' Enter 1 for UPRE, 2 for GCV, or 3 for DP. ');
for j = 1:nsamps
    h = waitbar(j/nsamps);
    if param_choice == 1
        % Find the UPRE choice for k (see Section 2.2)
        U_fn = @(k) norm(Utb(k+1:n,j))^2+2*sigma^2*k;
        Uvals = zeros(n,1);
        for i=1:n, Uvals(i)=U_fn(i); end
        ksamps(j) = find(Uvals == min(Uvals(1:60)));
    elseif param_choice == 2
        % Find the GCV choice for k
        G_fn = @(k) norm(Utb(k+1:n,j))^2/(n-k)^2;
        Gvals = zeros(n,1);
        for i=1:n, Gvals(i)=G_fn(i); end
        ksamps(j) = find(Gvals == min(Gvals(1:60)));
    elseif param_choice == 3
        D_fn = @(k) norm(Utb(k+1:n,j))^2-n*sigma^2;
        Dvals = zeros(n,1);
        for i=1:n, Dvals(i)=D_fn(i); end
        ksamps(j) = min(find(Dvals<=0));
    end
end
close(h)
figure(1), hist(ksamps,20)