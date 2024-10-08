function model = kriging_fit2(X_train, Y_train, V)


[n,k] = size(X_train);
ly = size(Y_train,1);
F = V;
Ft = F'; % transpose of F
q = size(V,2);

% estimation

% initialization
theta0 = [1e-1*ones(1,k-1),10]; delta0 = 1e-3; iterations = 50;

maxLS0 = -likelihood(X_train, Y_train, V, @corrGaussian, theta0, delta0);
dLS=abs(maxLS0);
options=optimset('Algorithm','sqp','Display','off','MaxFunEvals',100,'MaxIter',50);
i=0;
while dLS>1e-3 && i<iterations    %(i can be smaller otherwise the convergence is time-consuming)
    i=i+1; 
    % MLE to parameter estimation
    theta0=fmincon(@(theta) likelihood(X_train, Y_train, V, @corrGaussian, theta, delta0),...
        theta0, [], [], [], [], [7e-2*ones(1,k-1),1], [5e-1*ones(1,k-1),20], [], options);
    delta0=fmincon(@(delta) likelihood(X_train, Y_train, V, @corrGaussian, theta0, delta),...
        delta0, [], [], [], [], 1e-5, 1e-3, [], options);
    % calculate likelihood
    maxLS = -likelihood(X_train, Y_train, V, @corrGaussian, theta0, delta0);
    dLS=maxLS-maxLS0; 
    maxLS0=maxLS;
end

Rx = corrGaussian(theta0(:), X_train); % the correlation matrix of inputs
Rx = Rx + delta0*eye(n);
triangle = chol(Rx);
tr_inv = eye(n)/triangle;
Sigy_inv = tr_inv*tr_inv';
% Sigy_inv = eye(n)/Rx;

FK = Ft*Sigy_inv*F+1e-5*eye(q);
beta0 = FK\Ft*Sigy_inv*Y_train;

model.sigy_inv = Sigy_inv;
model.theta = theta0;
model.beta = beta0;
% sigma0 = (Y_train'-beta0'*Ft)*Sigy_inv*(Y_train-F*beta0)/ly;

end