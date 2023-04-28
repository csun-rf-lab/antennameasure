function [g, lambda] = calc_gain(f, geometry)
    a = geometry.a;
    b = geometry.b;
    l_h = geometry.l_h;
    l_e = geometry.l_e;

    % from NRL report page 8
    C = @fresnelc;
    S = @fresnels;

    c = 3e8;
    lambda = c./f * 39.37; % wavelength in inches
    u = (sqrt(lambda*l_h)/a + a./sqrt(lambda*l_h)) / sqrt(2);
    v = (sqrt(lambda*l_h)/a - a./sqrt(lambda*l_h)) / sqrt(2);
    w = b ./ sqrt(2*lambda*l_e);

    % eq. 3
    GH = (4*pi*l_h/a) * ((C(u) - C(v)).^2 + (S(u) - S(v)).^2);

    % eq. 4
    GE = (64*l_e/(pi*b)) * (C(w).^2 + S(w).^2);

    % eq. 5
    g = GE .* GH / (32/pi);
end
