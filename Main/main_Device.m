matext = '.mat';
% Cree MOSFET
path = '.\devices\Cree_C3M0015065K_SiC_650V.xlsx';
[pathstr, name, ~] = fileparts(path);
if ~isfile(fullfile(pathstr, name, matext))
    device = Device(path, DeviceType.MOSFET);
    save(fullfile(pathstr, name), 'device');
end
% Infineon IGBT
path = '.\devices\Infineon_IKZ75N65EL5_650V_withoutRecovery.xlsx';
[pathstr, name, ~] = fileparts(path);
if ~isfile(fullfile(pathstr, name, matext))
    device = Device(path, DeviceType.IGBT);
    save(fullfile(pathstr, name), 'device');
end
% Infineon CoolMOS
path = '.\devices\Infineon_IPW65R019C7_CoolMOS_650V.xlsx';
[pathstr, name, ~] = fileparts(path);
if ~isfile(fullfile(pathstr, name, matext))
    device = Device(path, DeviceType.CoolMOS);
    save(fullfile(pathstr, name), 'device');
end
% Rohm MOSFET
path = '.\devices\Rohm_sct3017alhr_SiC_650V.xlsx';
[pathstr, name, ~] = fileparts(path);
if ~isfile(fullfile(pathstr, name, matext))
    device = Device(path, DeviceType.MOSFET);
    save(fullfile(pathstr, name), 'device');
end
