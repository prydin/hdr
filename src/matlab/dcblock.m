echo off

size = 100000

bits = 15;
maxvalue = 2^bits;

t = linspace(0, 2*pi, size);
x = floor(cos(t*10)*maxvalue/4+maxvalue/2);
y = 1:size;

alpha = floor(0.9999 * maxvalue)
old_y = 0
old_x = 0
for n = 1:size;
  y(n) = x(n) - old_x + floor(floor(old_y * alpha) / maxvalue);
  d = x(n) - old_x
  old_y = y(n);
  old_x = x(n);
end
plot(y)
