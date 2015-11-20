u = udp('10.6.66.10',1337);
fopen(u)

N = 112;    % number of LEDs

phi = 0;
for i=1:10000
    for s=1:15  % we have 15 strips
        % use HSL mode, create a simple sign wave on hue, fixed values for
        % saturation and luminance
      
        %       hue                             sat       lum
        hsl = [0.5*(1+sin(2*pi*[1:N]'/N + phi)) ones(N,1) 0.5*ones(N,1)];
        rgb = hsl2rgb(hsl);   % convert our data to RGB
        % convert to 8 bit unsigned int
        data = uint8(rgb*255);
        
        % reshape the matrix into a vector and append which strip we send to 
        
        dgram = [s-1 reshape(data',1,[])];
        %step(H, dgram);  % transmit the UDP datagram
        fwrite(u,dgram);
    end;
    pause(0.01);    % sleep for 10ms
    phi = phi + 0.01 * 2*pi*0.5;
end;
