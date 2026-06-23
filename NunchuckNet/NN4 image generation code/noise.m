function image=noise(image)

image=imnoise(image,'poisson');

base_level=0.2*rand;
noiseLevel=0.008*rand+0.002;
image=imnoise(image,'gaussian',base_level,noiseLevel);
end