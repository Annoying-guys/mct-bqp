function [homographies, invhomographies] = loadHomographies(filename, dataset, cameras)
    % Given a filename, load homographies
    % Inputs
    %  filename: filename with homographies
    %  dataset: tag of the dataset

    % Output
    %  homographies: 3x3 homography matrices
    %  invhomographies: 3x3 inverse of the previous homographies
    homographies = cell(length(cameras),1); invhomographies = homographies;
    if strcmp(dataset, 'hda') == 1
        for i=1:length(cameras)
            homographies{i} = dlmread(strcat(filename, '/cam', num2str(cameras{i}), 'homography.txt'));
            invhomographies{i} = inv(homographies{i});
        end
    end
    if strcmp(dataset, 'campus_2') == 1
        homographies_struct = load(filename);
        homographies{1} = homographies_struct.TFORM_alameda.tdata.T;
        homographies{2} = homographies_struct.TFORM_central.tdata.T;
        invhomographies{1} = homographies_struct.TFORM_alameda.tdata.Tinv;
        invhomographies{2} = homographies_struct.TFORM_central.tdata.Tinv;
    end
    if strcmp(dataset, 'ucla') == 1
        homographies_struct = load(filename);
        homographies_struct = homographies_struct.cam_param;
        for i=1:length(cameras)
            K = homographies_struct(i).K % Intrinsic
            R = homographies_struct(i).R % Extrinsic
            T = homographies_struct(i).T % Extrinsic
            lambda = homographies_struct(i).scale;
            % Check for orthogonality
            ortho_check = cross(R(:,1),R(:,2)); % This should be R(:,3)
            if R(:,3) ~= ortho_check
                disp('3rd column of R is not R1 cross R2!');
            end
            homographies{i} = lambda * K * [R(:,1) R(:,2) T];
            invhomographies{i} = inv(homographies{i});
        end
    end
end
