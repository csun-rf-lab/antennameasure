function details = sgh_antenna_geometry(antenna)
    % from page 22

    % a, b, l_h, l_e all in inches
    % frequencies in Hz
    if antenna == "8mm"
        % 8 mm band
        a = 2.720;
        b = 2.231;
        l_h = 6.513;
        l_e = 7.197;
        f_low = 26.550e9;
        f_high = 38.960e9;
    elseif antenna == "1.25cm"
        % 1.25 cm band
        a = 4.000;
        b = 3.281;
        l_h = 9.706;
        l_e = 9.113;
        f_low = 18.070e9;
        f_high = 26.550e9;
    elseif antenna == "1.8cm" %12-12
        % 1.8 cm band
        a = 5.984;
        b = 4.908;
        l_h = 14.333;
        l_e = 13.633;
        f_low = 12.4e9;
        f_high = 18.070e9;
    elseif antenna == "3.2cm" %12-8.2
        % 3.2 cm band
        a = 7.654;
        b = 5.669;
        l_h = 13.484;
        l_e = 12.598;
        f_low = 8.100e9;
        f_high = 12.4e9;
    elseif antenna == "4.75cm" %12-5.8
        % 4.75 cm band
        a = 11.360;
        b = 8.415;
        l_h = 20.014;
        l_e = 18.700;
        f_low = 5.770e9;
        f_high = 8.330e9;
    elseif antenna == "3.95cm"
        % 3.95 cm band
        a = 5.041;
        b = 3.733;
        l_h = 7.447;
        l_e = 6.555;
        f_low = 6.980e9;
        f_high = 10e9;
    elseif antenna == "6cm" %12-3.9
        % 6 cm band
        a = 8.507;
        b = 6.300;
        l_h = 12.462;
        l_e = 11.062;
        f_low = 3.950e9;
        f_high = 5.880e9;
    elseif antenna == "10cm" %12-2.6
        % 10 cm band
        a = 12.760;
        b = 9.450;
        l_h = 18.682;
        l_e = 16.593;
        f_low = 2.600e9;
        f_high = 3.950e9;
    elseif antenna == "15cm" %12-1.7
        % 15 cm band
        a = 14.508;
        b = 10.747;
        l_h = 16.508;
        l_e = 14.107;
        f_low = 1.700e9;
        f_high = 2.600e9;
    elseif antenna == "23cm" %12-1.1
        % 23 cm band
        a = 21.931;
        b = 16.245;
        l_h = 24.955;
        l_e = 21.325;
        f_low = 1.130e9;
        f_high = 1.700e9;
    elseif antenna == "30cm" %12-0.9
        % 30 cm band
        a = 21.931;
        b = 16.245;
        l_h = 28.730;
        l_e = 24.000;
        f_low = 0.950e9;
        f_high = 1.150e9;
    else
        error("Unknown standard gain horn");
    end

    details.a = a;
    details.b = b;
    details.l_h = l_h;
    details.l_e = l_e;
    details.f_low = f_low;
    details.f_high = f_high;
end

