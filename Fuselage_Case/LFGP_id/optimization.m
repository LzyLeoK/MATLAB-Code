function [model] = optimization(X, Xt, Y, A, U, D, corr_2, s, theta0, delta0, iterations)
% Y is smn functional outputs for s replications and U is smn*nk basis matrix
Y = Y(:);
[n,q] = size(X);
p = length(A);
ly = length(Y);
m = ly/(n*s); % m-dimensional outputs corresponding to each input
Fx = [ones(n,1),X];
f = kron(Fx,ones(m,1));
ft = kron(Fx',ones(1,m)); % transpose of f
F = kron(ones(s,1),f);
Ft = kron(ones(1,s),ft); % transpose of F
pq = size(F,2);

maxLS0 = -objective_function(X, Xt, Y, A, U, D, corr_2, s, theta0, delta0);
dLS = abs(maxLS0);
options = optimset('Algorithm','sqp', 'Display','off');
i = 0;
while dLS>1e-3 && i<iterations
    i=i+1;
    % MLE to parameter estimation
    theta0=fmincon(@(theta) objective_function(X, Xt, Y, A, U, D, corr_2, s, theta, delta0), ...
        theta0, [], [], [], [], 1.4e-7*ones(1,q), 1e-5*ones(1,q), [], options);
    delta0=fmincon(@(delta) objective_function(X, Xt, Y, A, U, D, corr_2, s, theta0, delta), ...
        delta0, [], [], [], [], 1e-4, 1, [], options);
    % calculate likelihood
    maxLS = -objective_function(X, Xt, Y, A, U, D, corr_2, s, theta0, delta0);
    dLS = maxLS-maxLS0;
    maxLS0 = maxLS;
end
    
    

Sig = eye(p);
Rx = corr_2(theta0(:), X); % the correlation matrix of inputs
R1 = corr_2(theta0(:), Xt, X);
Rt = kron(R1,Sig);
Sig_inv = eye(p)/Sig;
Rx_inv = eye(n)/Rx;
R_inv = kron(Rx_inv,Sig_inv);
omega = delta0*R_inv+U'*U + 1e-5*eye(n*p);
omega_inv = eye(n*p)/omega;

Sigy_inv = eye(ly)/delta0-U*omega_inv*U'/delta0; % SMW
gamma = D*Rt*U'*Sigy_inv;
FK = Ft*Sigy_inv*F+1e-5*eye(pq);
Fg = gamma*F/FK*Ft;
FG = Fg*gamma';

[Q,S] = qr(FG);
S = 1e10*S+1e-5*eye(2);
K = Q'*(Fg*Sigy_inv*Y-gamma*Y);
lamda0 = 1e10*eye(2)/S*K;

beta0 = FK\Ft*(Sigy_inv*Y-gamma'*lamda0);
% sigma0 = (Y'-beta0'*Ft)*Sigy_inv*(Y-F*beta0)/ly;


model.theta = theta0;
model.delta = delta0;
model.beta = beta0;
model.iteration = i;

end