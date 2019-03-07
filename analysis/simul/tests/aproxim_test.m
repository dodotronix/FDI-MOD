clc;
clear all;
close all;

addpath("../")

%packages
pkg load signal;
pkg load miscellaneous;

%%  setups
fs_analog  =  10e9;     % analog signal sampling frequency [Hz]
fs_adc     =  125e6;    % ADC sampling frequency [Hz]
order      =  5;        % lfsr order (from 3 up to 13) [-]
amp        =  0.5;      % amplitude of generated signal [V]
bitrate    =  25e6;     % generator output bitrate [bit/s]
vf         =  0.695;    % velocity factor [-]
cable_len  =  3*2.919;  % cable length [m]
cable_gain =  -9;       % gain of the cable [dB]
repeat     =  3;        % signal repetition number

%% application simulation

% generate sequence
[G,t] = lfsrgen(bitrate, order, amp, fs_analog);
[G2, t2] = repeater(G, t, repeat);

% output of generator
S_ref = lpass(G, fs_analog);
S_forward = lpass(G2, fs_analog);
%S_ref = G;
%S_forward = G2;

% cable delay
[S_back, t_back] = cable(S_forward, t, cable_len, cable_gain, vf);

% addition of signal 'S_forward' and reflected signal 'S_back'
S_out = [S_forward, zeros(1, length(S_back)-length(S_forward))] + S_back;
t_out = [0:length(S_out)-1]/fs_analog;

% get undersampled signal (forward and out)
smp_S_ref = sampler(S_ref, t, fs_adc);
[smp_S_out, smp_t_out] = sampler(S_out, t_out, fs_adc);

% calculate correlation (S_forward is reference signal)
[xS_out, xd] = xcorrela(S_ref, S_out, fs_analog, repeat, vf, bitrate);
[xS_out_smp, xd_smp] = xcorrela(smp_S_ref, smp_S_out, fs_adc, repeat, vf, bitrate);

% normalization
% TODO make accurate normalization
xS_out = xS_out/max(xS_out);
xS_out_smp = xS_out_smp/max(xS_out_smp);

% spline regression
regress_spline = spline(xd_smp, xS_out_smp, xd);

% plot analog sampled signal in time-domain
figure(1)
subplot(2,1,1)
plot(t_out, S_out)
grid on
subplot(2,1,2)
plot(smp_t_out, smp_S_out)
grid on

% plot correlations (analog and digitalized signal)
figure(2)
plot(xd, xS_out/max(xS_out))
hold on
stem(xd_smp, xS_out_smp/max(xS_out_smp))
grid on
plot(xd, regress_spline)
hold on

% TODO polynomial regression -> use for extrapolating peaks
%p = polyfit(d_S_add_smp, xc_smp, 14);
%y = polyval(p, d_S_add);
%plot(d_S_add, y)

