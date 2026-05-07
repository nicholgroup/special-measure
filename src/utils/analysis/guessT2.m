function out = guessT2(x,y)
% guessT2 guesses T2 decay 
% x is time
% y is decaying signal (oscillations)

sf = 10;
shifty = (y - range(y)/2)*2;
smy = smooth(abs(shifty),sf);
init_y = smy(sf);
ydrop = (1-exp(-1))*init_y;
[~,t2guessInd] = min(abs(smy-ydrop));
T2guess = x(t2guessInd);

out = T2guess;

end